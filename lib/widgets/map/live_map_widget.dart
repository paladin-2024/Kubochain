import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/constants/app_colors.dart';

class LiveMapWidget extends StatelessWidget {
  final LatLng center;
  final double zoom;
  final LatLng? pickupLocation;
  final LatLng? destinationLocation;
  final LatLng? driverLocation;
  final List<LatLng> routePoints;
  final MapController? mapController;
  final bool isDark;

  const LiveMapWidget({
    super.key,
    required this.center,
    this.zoom = 15,
    this.pickupLocation,
    this.destinationLocation,
    this.driverLocation,
    this.routePoints = const [],
    this.mapController,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: center,
        initialZoom: zoom,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.kubochain.app',
        ),
        if (routePoints.length > 1)
          PolylineLayer(
            polylines: [
              Polyline(
                points: routePoints,
                color: AppColors.primary,
                strokeWidth: 4,
              ),
            ],
          ),
        MarkerLayer(
          markers: [
            // Current/pickup location
            if (pickupLocation != null)
              Marker(
                point: pickupLocation!,
                width: 40,
                height: 40,
                child: _LocationMarker(
                  color: AppColors.primary,
                  icon: Icons.my_location,
                ),
              ),
            // Destination
            if (destinationLocation != null)
              Marker(
                point: destinationLocation!,
                width: 40,
                height: 40,
                child: _LocationMarker(
                  color: AppColors.error,
                  icon: Icons.location_on,
                ),
              ),
            // Driver
            if (driverLocation != null)
              Marker(
                point: driverLocation!,
                width: 44,
                height: 44,
                child: _DriverMarker(),
              ),
          ],
        ),
      ],
    );
  }
}

class _LocationMarker extends StatelessWidget {
  final Color color;
  final IconData icon;

  const _LocationMarker({required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.4), blurRadius: 8, spreadRadius: 2),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 22),
    );
  }
}

class _DriverMarker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8),
        ],
      ),
      child: const Icon(Icons.directions_bike, color: AppColors.primary, size: 24),
    );
  }
}
