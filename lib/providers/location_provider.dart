import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../core/services/location_service.dart';

class LocationProvider extends ChangeNotifier {
  LatLng? _currentLocation;
  String _currentAddress = '';
  bool _isLoading = false;
  String? _error;

  LatLng? get currentLocation => _currentLocation;
  String get currentAddress => _currentAddress;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();
    final position = await LocationService.getCurrentPosition();
    if (position != null) {
      _currentLocation = LatLng(position.latitude, position.longitude);
      _currentAddress = await LocationService.getAddressFromLatLng(
        position.latitude,
        position.longitude,
      );
    } else {
      _error = 'Could not get location';
    }
    _isLoading = false;
    notifyListeners();
  }

  void startTracking() {
    LocationService.positionStream().listen((Position position) {
      _currentLocation = LatLng(position.latitude, position.longitude);
      notifyListeners();
    });
  }

  void updateAddress(String address) {
    _currentAddress = address;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
