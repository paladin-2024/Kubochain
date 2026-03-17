import 'package:flutter/material.dart';
import '../models/ride_model.dart';
import '../core/services/api_service.dart';
import '../core/services/socket_service.dart';
import '../core/services/location_service.dart';
import '../core/services/notification_service.dart';

class DriverProvider extends ChangeNotifier {
  bool _isOnline = false;
  RideModel? _pendingRequest;
  RideModel? _activeRide;
  List<RideModel> _completedRides = [];
  double _todayEarnings = 0;
  double _totalEarnings = 0;
  bool _isLoading = false;
  String? _error;
  bool _listeningForRequests = false;

  bool get isOnline => _isOnline;
  RideModel? get pendingRequest => _pendingRequest;
  RideModel? get activeRide => _activeRide;
  List<RideModel> get completedRides => _completedRides;
  double get todayEarnings => _todayEarnings;
  double get totalEarnings => _totalEarnings;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void listenToRideRequests() {
    if (_listeningForRequests) return; // prevent duplicate listeners
    _listeningForRequests = true;
    SocketService.onNewRideRequest((data) {
      if (data['ride'] != null) {
        _pendingRequest = RideModel.fromJson(data['ride']);
        notifyListeners();
        // Trigger local notification + sound so driver is alerted
        NotificationService.show(
          title: 'New Ride Request!',
          body:
              'Pickup: ${_pendingRequest!.pickup.address.split(',').first} → ${_pendingRequest!.destination.address.split(',').first}',
          type: 'ride_request',
        );
      }
    });
  }

  void stopListeningForRequests() {
    _listeningForRequests = false;
    SocketService.off('ride:newRequest');
  }

  Future<void> toggleOnline(bool value) async {
    try {
      await ApiService.toggleAvailability(value);
      _isOnline = value;
      SocketService.setDriverOnline(value);
      if (value) {
        listenToRideRequests();
        _startLocationTracking();
      } else {
        stopListeningForRequests();
      }
      notifyListeners();
    } catch (_) {
      _error = 'Failed to update availability';
      notifyListeners();
    }
  }

  void _startLocationTracking() {
    LocationService.positionStream().listen((position) {
      SocketService.sendDriverLocation(position.latitude, position.longitude);
      ApiService.updateDriverLocation(position.latitude, position.longitude);
    });
  }

  Future<bool> acceptRide() async {
    if (_pendingRequest == null) return false;
    try {
      final res = await ApiService.acceptRide(_pendingRequest!.id);
      _activeRide = RideModel.fromJson(res.data['ride']);
      SocketService.joinRideRoom(_activeRide!.id);
      _pendingRequest = null;
      notifyListeners();
      return true;
    } catch (_) {
      _error = 'Failed to accept ride';
      notifyListeners();
      return false;
    }
  }

  void declineRequest() {
    _pendingRequest = null;
    notifyListeners();
  }

  /// Called when rider taps a FCM notification to load the ride from the API
  Future<void> loadRideFromNotification(String rideId) async {
    try {
      final res = await ApiService.getRide(rideId);
      final ride = RideModel.fromJson(res.data['ride']);
      // Only show if ride is still pending
      if (ride.status == 'pending') {
        _pendingRequest = ride;
        notifyListeners();
      }
    } catch (_) {
      // Ride may already be taken — silently ignore
    }
  }

  Future<void> notifyArrived() async {
    if (_activeRide == null) return;
    SocketService.notifyArrived(_activeRide!.id);
  }

  Future<bool> startTrip() async {
    if (_activeRide == null) return false;
    try {
      final res = await ApiService.startRide(_activeRide!.id);
      _activeRide = RideModel.fromJson(res.data['ride']);
      notifyListeners();
      return true;
    } catch (_) {
      _error = 'Failed to start trip';
      notifyListeners();
      return false;
    }
  }

  Future<bool> completeTrip() async {
    if (_activeRide == null) return false;
    try {
      final res = await ApiService.completeRide(_activeRide!.id);
      final completedRide = RideModel.fromJson(res.data['ride']);
      _todayEarnings += completedRide.price;
      _completedRides.insert(0, completedRide);
      SocketService.leaveRideRoom(_activeRide!.id);
      _activeRide = null;
      notifyListeners();
      return true;
    } catch (_) {
      _error = 'Failed to complete trip';
      notifyListeners();
      return false;
    }
  }

  Future<void> loadEarnings() async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await ApiService.getDriverEarnings();
      _todayEarnings = (res.data['todayEarnings'] ?? 0).toDouble();
      _totalEarnings = (res.data['totalEarnings'] ?? 0).toDouble();
      final List rides = res.data['recentRides'] ?? [];
      _completedRides = rides.map((r) => RideModel.fromJson(r)).toList();
    } catch (_) {
      _error = 'Failed to load earnings';
    }
    _isLoading = false;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
