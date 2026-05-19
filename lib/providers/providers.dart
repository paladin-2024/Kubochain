import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_provider.dart';
import 'ride_provider.dart';
import 'location_provider.dart';
import 'driver_provider.dart';

final authProvider = ChangeNotifierProvider<AuthProvider>((ref) => AuthProvider());
final rideProvider = ChangeNotifierProvider<RideProvider>((ref) => RideProvider());
final locationProvider = ChangeNotifierProvider<LocationProvider>((ref) => LocationProvider());
final driverProvider = ChangeNotifierProvider<DriverProvider>((ref) => DriverProvider());
