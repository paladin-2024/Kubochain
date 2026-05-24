import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:latlong2/latlong.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/ride_provider.dart';
import '../../providers/providers.dart';
import '../../widgets/map/live_map_widget.dart';
import 'rate_driver_screen.dart';
import 'airtel_payment_screen.dart';

class TripScreen extends ConsumerStatefulWidget {
  const TripScreen({super.key});

  @override
  ConsumerState<TripScreen> createState() => _TripScreenState();
}

class _TripScreenState extends ConsumerState<TripScreen> {
  @override
  void initState() {
    super.initState();
    final ride = ref.read(rideProvider);
    if (ride.currentRide != null) {
      ride.loadRoutePoints(
        LatLng(ride.currentRide!.pickup.lat, ride.currentRide!.pickup.lng),
        LatLng(ride.currentRide!.destination.lat, ride.currentRide!.destination.lng),
      );
    }
    ride.addListener(_onStatusChange);
  }

  void _onStatusChange() {
    final ride = ref.read(rideProvider);
    if (ride.rideStatus == RideStatus.completed && mounted) {
      HapticFeedback.mediumImpact();
      final currentRide = ride.currentRide;
      final method = currentRide?.paymentMethod ?? 'cash';
      if (method == 'airtel_money' || method == 'mtn_momo') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => AirtelPaymentScreen(
              rideId: currentRide!.id,
              amount: currentRide.price,
              pickupAddress: currentRide.pickup.address,
              destinationAddress: currentRide.destination.address,
              driverName: currentRide.driver?['first_name'] as String?,
            ),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const RateDriverScreen()),
        );
      }
    }
    if (ride.rideStatus == RideStatus.awaitingConfirmation && mounted) {
      HapticFeedback.mediumImpact();
      setState(() {});
    }
  }

  @override
  void dispose() {
    ref.read(rideProvider).removeListener(_onStatusChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ride = ref.watch(rideProvider);
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
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    HugeIcon(icon: HugeIcons.strokeRoundedMotorbike01, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Trajet en cours',
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _TripStat(
                          icon: HugeIcons.strokeRoundedRoute01,
                          value: '${currentRide.distance.toStringAsFixed(1)} km',
                          label: 'Distance',
                        ),
                        _TripStat(
                          icon: HugeIcons.strokeRoundedMoney01,
                          value: 'FC ${currentRide.price.toStringAsFixed(0)}',
                          label: 'Tarif',
                        ),
                        if (currentRide.driver != null)
                          _TripStat(
                            icon: HugeIcons.strokeRoundedUser,
                            value: currentRide.driver!['firstName'] ?? '',
                            label: 'Conducteur',
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
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  boxShadow: AppColors.cardShadow,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const HugeIcon(icon: HugeIcons.strokeRoundedCheckmarkBadge01, color: Color(0xFF00C853), size: 48),
                    const SizedBox(height: 12),
                    const Text(
                      'Trajet terminé !',
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Votre conducteur a terminé le trajet.\nVeuillez confirmer pour valider.',
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
                          HapticFeedback.mediumImpact();
                          final ok = await ref.read(rideProvider).passengerConfirmRide();
                          if (!ok && mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Échec de la confirmation. Réessayez.')),
                            );
                          }
                        },
                        child: const Text(
                          'Confirmer la fin du trajet',
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
        HugeIcon(icon: icon, color: AppColors.primary, size: 24),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
}
