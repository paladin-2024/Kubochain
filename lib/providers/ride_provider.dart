import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../models/ride_model.dart';
import '../core/services/api_service.dart';
import '../core/services/socket_service.dart';
import '../core/services/location_service.dart';
import '../core/services/notification_service.dart';

enum RideStatus { idle, searching, found, arriving, inProgress, completed, cancelled, error }

class RideProvider extends ChangeNotifier {
  RideStatus _rideStatus = RideStatus.idle;
  RideModel? _currentRide;
  List<RideModel> _rideHistory = [];
  LatLng? _driverLocation;
  List<LatLng> _routePoints = [];
  String? _error;
  bool _isLoading = false;
  int _driverEta = 0; // minutes

  RideStatus get rideStatus => _rideStatus;
  RideModel? get currentRide => _currentRide;
  List<RideModel> get rideHistory => _rideHistory;
  LatLng? get driverLocation => _driverLocation;
  List<LatLng> get routePoints => _routePoints;
  String? get error => _error;
  bool get isLoading => _isLoading;
  int get driverEta => _driverEta;

  void listenToRideEvents() {
    // Clear previous listeners before registering new ones
    SocketService.off('ride:accepted');
    SocketService.off('ride:driverLocation');
    SocketService.off('ride:driverArrived');
    SocketService.off('ride:started');
    SocketService.off('ride:completed');
    SocketService.off('ride:cancelled');

    SocketService.onRideAccepted((data) {
      _rideStatus = RideStatus.found;
      if (data['ride'] != null) {
        _currentRide = RideModel.fromJson(data['ride']);
      }
      notifyListeners();
      NotificationService.show(
        title: 'Driver Accepted!',
        body: 'Your driver is on the way to pick you up.',
        type: 'ride_accepted',
      );
    });

    SocketService.onDriverLocation((data) {
      _driverLocation = LatLng(
        (data['lat'] as num).toDouble(),
        (data['lng'] as num).toDouble(),
      );
      if (data['eta'] != null) _driverEta = data['eta'];
      notifyListeners();
    });

    SocketService.onDriverArrived((data) {
      _rideStatus = RideStatus.arriving;
      notifyListeners();
      NotificationService.show(
        title: 'Driver Arrived!',
        body: 'Your driver is waiting at the pickup location.',
        type: 'driver_arrived',
      );
    });

    SocketService.onRideStarted((data) {
      _rideStatus = RideStatus.inProgress;
      notifyListeners();
      NotificationService.show(
        title: 'Trip Started',
        body: 'Your trip is now in progress.',
        type: 'trip_started',
      );
    });

    SocketService.onRideCompleted((data) {
      _rideStatus = RideStatus.completed;
      if (data['ride'] != null) {
        _currentRide = RideModel.fromJson(data['ride']);
      }
      notifyListeners();
      NotificationService.show(
        title: 'Trip Completed',
        body: 'You have arrived. Please rate your driver.',
        type: 'trip_completed',
      );
    });

    SocketService.onRideCancelled((data) {
      _rideStatus = RideStatus.cancelled;
      _error = data['reason'] ?? 'Ride was cancelled';
      notifyListeners();
      NotificationService.show(
        title: 'Ride Cancelled',
        body: _error ?? 'Your ride has been cancelled.',
        type: 'ride_cancelled',
      );
    });
  }

  Future<bool> requestRide({
    required LocationPoint pickup,
    required LocationPoint destination,
    required String rideType,
    required double price,
    required double distance,
  }) async {
    _isLoading = true;
    _rideStatus = RideStatus.searching;
    _error = null;
    notifyListeners();
    try {
      final res = await ApiService.createRide({
        'pickup': pickup.toJson(),
        'destination': destination.toJson(),
        'rideType': rideType,
        'price': price,
        'distance': distance,
      });
      _currentRide = RideModel.fromJson(res.data['ride']);
      SocketService.joinRideRoom(_currentRide!.id);
      listenToRideEvents();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _rideStatus = RideStatus.idle;
      _error = 'Failed to request ride. Please try again.';
      notifyListeners();
      return false;
    }
  }

  Future<void> cancelRide(String reason) async {
    if (_currentRide == null) return;
    try {
      await ApiService.cancelRide(_currentRide!.id, reason);
      if (_currentRide != null) {
        SocketService.leaveRideRoom(_currentRide!.id);
      }
      _rideStatus = RideStatus.idle;
      _currentRide = null;
      _driverLocation = null;
      _routePoints = [];
    } catch (e) {
      _error = 'Failed to cancel ride';
    }
    notifyListeners();
  }

  Future<bool> rateRide(int rating, String comment, {List<String> tags = const []}) async {
    if (_currentRide == null) return false;
    try {
      await ApiService.rateRide(_currentRide!.id, rating, comment, tags: tags);
      resetRide();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> loadRoutePoints(LatLng from, LatLng to) async {
    _routePoints = await LocationService.getRoute(from, to);
    notifyListeners();
  }

  Future<void> fetchRideHistory() async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await ApiService.getMyRides();
      final List rides = res.data['rides'] ?? [];
      _rideHistory = rides.map((r) => RideModel.fromJson(r)).toList();
    } catch (_) {
      _error = 'Failed to load ride history';
    }
    _isLoading = false;
    notifyListeners();
  }

  void resetRide() {
    _rideStatus = RideStatus.idle;
    _currentRide = null;
    _driverLocation = null;
    _routePoints = [];
    _driverEta = 0;
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
