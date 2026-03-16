import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:dio/dio.dart';

class LocationService {
  static final Dio _dio = Dio();

  static Future<bool> requestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    if (permission == LocationPermission.deniedForever) return false;
    return true;
  }

  static Future<Position?> getCurrentPosition() async {
    final hasPermission = await requestPermission();
    if (!hasPermission) return null;
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  static Stream<Position> positionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    );
  }

  // Reverse geocoding using Nominatim (OpenStreetMap, free)
  static Future<String> getAddressFromLatLng(double lat, double lng) async {
    try {
      final response = await _dio.get(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: {
          'lat': lat,
          'lon': lng,
          'format': 'json',
        },
        options: Options(headers: {'User-Agent': 'KuboChain/1.0'}),
      );
      final data = response.data;
      return data['display_name'] ?? 'Unknown location';
    } catch (_) {
      return 'Unknown location';
    }
  }

  // Search places using Nominatim
  static Future<List<PlaceResult>> searchPlaces(String query) async {
    try {
      final response = await _dio.get(
        'https://nominatim.openstreetmap.org/search',
        queryParameters: {
          'q': query,
          'format': 'json',
          'limit': 5,
        },
        options: Options(headers: {'User-Agent': 'KuboChain/1.0'}),
      );
      final List data = response.data;
      return data.map((item) => PlaceResult.fromJson(item)).toList();
    } catch (_) {
      return [];
    }
  }

  // Get route between two points using OSRM (free, open source)
  static Future<List<LatLng>> getRoute(LatLng from, LatLng to) async {
    try {
      final response = await _dio.get(
        'https://router.project-osrm.org/route/v1/driving'
        '/${from.longitude},${from.latitude}'
        ';${to.longitude},${to.latitude}',
        queryParameters: {'geometries': 'geojson', 'overview': 'full'},
      );
      final coords = response.data['routes'][0]['geometry']['coordinates'] as List;
      return coords.map((c) => LatLng(c[1].toDouble(), c[0].toDouble())).toList();
    } catch (_) {
      return [from, to];
    }
  }

  // Calculate distance in km
  static double distanceKm(LatLng from, LatLng to) {
    const distance = Distance();
    return distance.as(LengthUnit.Kilometer, from, to);
  }

  // Estimate price in Congolese Francs (CDF)
  static double estimatePrice(double distanceKm) {
    const basePrice = 1000.0; // FC base fare
    const pricePerKm = 500.0; // FC per km
    return basePrice + (distanceKm * pricePerKm);
  }
}

class PlaceResult {
  final String displayName;
  final double lat;
  final double lng;

  PlaceResult({
    required this.displayName,
    required this.lat,
    required this.lng,
  });

  factory PlaceResult.fromJson(Map<String, dynamic> json) {
    return PlaceResult(
      displayName: json['display_name'] ?? '',
      lat: double.parse(json['lat'].toString()),
      lng: double.parse(json['lon'].toString()),
    );
  }
}
