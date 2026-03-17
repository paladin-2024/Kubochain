import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/ride_provider.dart';
import '../../widgets/map/live_map_widget.dart';
import 'rate_driver_screen.dart';

class TripScreen extends StatefulWidget {
  const TripScreen({super.key});

  @override
  State<TripScreen> createState() => _TripScreenState();
}

class _TripScreenState extends State<TripScreen> {
  @override
  void initState() {
    super.initState();
    final ride = context.read<RideProvider>();
    if (ride.currentRide != null) {
      ride.loadRoutePoints(
        LatLng(ride.currentRide!.pickup.lat, ride.currentRide!.pickup.lng),
        LatLng(ride.currentRide!.destination.lat, ride.currentRide!.destination.lng),
      );
    }
    ride.addListener(_onStatusChange);
  }

  void _onStatusChange() {
    final ride = context.read<RideProvider>();
    if (ride.rideStatus == RideStatus.completed && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const RateDriverScreen()),
      );
    }
    if (ride.rideStatus == RideStatus.awaitingConfirmation && mounted) {
      setState(() {}); // rebuild to show confirmation button
    }
  }

  @override
  void dispose() {
    context.read<RideProvider>().removeListener(_onStatusChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ride = context.watch<RideProvider>();
    final currentRide = ride.currentRide;
    final driverLoc = ride.driverLocation;

    final center = driverLoc ??
        (currentRide != null
            ? LatLng(currentRide.pickup.lat, currentRide.pickup.lng)
            : AppConstants.defaultLocation);

    return Scaffold(
      body: Stack(
        children: [
          LiveMapWidget(
            center: center,
            pickupLocation: currentRide != null
                ? LatLng(currentRide.pickup.lat, currentRide.pickup.lng)
                : null,
            destinationLocation: currentRide != null
                ? LatLng(currentRide.destination.lat, currentRide.destination.lng)
                : null,
            driverLocation: driverLoc,
            routePoints: ride.routePoints,
          ),

          // Trip status badge
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.success,
                  borderRadius: BorderRadius.circular(50),
                  boxShadow: [
                    BoxShadow(color: AppColors.success.withOpacity(0.4), blurRadius: 8),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.directions_bike, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Trip in Progress',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom info card
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 16)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Destination
                  if (currentRide != null) ...[
                    Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            currentRide.destination.address.split(',').first,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 12),

                    // Trip stats
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _TripStat(
                          icon: Icons.route,
                          value: '${currentRide.distance.toStringAsFixed(1)} km',
                          label: 'Distance',
                        ),
                        _TripStat(
                          icon: Icons.monetization_on_outlined,
                          value: 'FC ${currentRide.price.toStringAsFixed(0)}',
                          label: 'Fare',
                        ),
                        if (currentRide.driver != null)
                          _TripStat(
                            icon: Icons.person_outline,
                            value: currentRide.driver!['firstName'] ?? '',
                            label: 'Driver',
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Passenger confirmation overlay
          if (ride.rideStatus == RideStatus.awaitingConfirmation)
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D1525),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 20)],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.flag_rounded, color: Color(0xFF00C853), size: 48),
                    const SizedBox(height: 12),
                    const Text(
                      'Trip Complete!',
                      style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Your driver has ended the trip.\nPlease confirm to complete.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF8899AA), fontSize: 14),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00C853),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: () async {
                          final ok = await context.read<RideProvider>().passengerConfirmRide();
                          if (!ok && mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Failed to confirm. Try again.')),
                            );
                          }
                        },
                        child: const Text(
                          'Confirm Trip Completion',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TripStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _TripStat({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 24),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
}
