import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
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
          urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
          subdomains: const ['a', 'b', 'c', 'd'],
          userAgentPackageName: 'com.kubochain.app',
        ),
        if (routePoints.length > 1)
          PolylineLayer(
            polylines: [
              Polyline(
                points: routePoints,
                color: AppColors.primary,
                strokeWidth: 5,
              ),
            ],
          ),
        MarkerLayer(
          markers: [
            if (pickupLocation != null)
              Marker(
                point: pickupLocation!,
                width: 48,
                height: 48,
                child: _LocationMarker(
                  color: AppColors.primary,
                  icon: HugeIcons.strokeRoundedGps01,
                ),
              ),
            if (destinationLocation != null)
              Marker(
                point: destinationLocation!,
                width: 48,
                height: 48,
                child: _LocationMarker(
                  color: AppColors.error,
                  icon: HugeIcons.strokeRoundedMapPin,
                ),
              ),
            if (driverLocation != null)
              Marker(
                point: driverLocation!,
                width: 52,
                height: 52,
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
          BoxShadow(color: color.withValues(alpha: 0.45), blurRadius: 12, spreadRadius: 2),
        ],
      ),
      child: HugeIcon(icon: icon, color: Colors.white, size: 26),
    );
  }
}

class _DriverMarker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: AppColors.primary.withValues(alpha: 0.25), blurRadius: 12, spreadRadius: 2),
        ],
      ),
      child: const HugeIcon(icon: HugeIcons.strokeRoundedMotorbike01, color: AppColors.primary, size: 28),
    );
  }
}
