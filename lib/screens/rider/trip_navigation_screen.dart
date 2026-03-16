import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/driver_provider.dart';
import '../../providers/location_provider.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/map/live_map_widget.dart';
import '../common/chat_screen.dart';
import 'rider_home_screen.dart';

class TripNavigationScreen extends StatefulWidget {
  const TripNavigationScreen({super.key});

  @override
  State<TripNavigationScreen> createState() => _TripNavigationScreenState();
}

class _TripNavigationScreenState extends State<TripNavigationScreen> {
  @override
  Widget build(BuildContext context) {
    final driver = context.watch<DriverProvider>();
    final location = context.watch<LocationProvider>();
    final activeRide = driver.activeRide;
    final center = location.currentLocation ?? AppConstants.defaultLocation;

    final isPickup = activeRide?.status == 'accepted' || activeRide?.status == 'arriving';
    final destination = isPickup
        ? (activeRide != null ? LatLng(activeRide.pickup.lat, activeRide.pickup.lng) : null)
        : (activeRide != null ? LatLng(activeRide.destination.lat, activeRide.destination.lng) : null);

    return Scaffold(
      body: Stack(
        children: [
          LiveMapWidget(
            center: center,
            pickupLocation: location.currentLocation,
            destinationLocation: destination,
            isDark: true,
          ),

          // Top status
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8)],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: isPickup ? AppColors.warning : AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isPickup ? 'Navigate to Pickup' : 'Navigate to Destination',
                            style: const TextStyle(
                              color: AppColors.textOnDark,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          if (activeRide != null)
                            Text(
                              isPickup
                                  ? activeRide.pickup.address.split(',').first
                                  : activeRide.destination.address.split(',').first,
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom action card
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 16)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (activeRide?.passenger != null) ...[
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: AppColors.primary.withOpacity(0.2),
                          child: Text(
                            (activeRide!.passenger!['firstName'] ?? 'P')[0].toUpperCase(),
                            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${activeRide.passenger!['firstName'] ?? ''} ${activeRide.passenger!['lastName'] ?? ''}',
                                style: const TextStyle(color: AppColors.textOnDark, fontWeight: FontWeight.w600, fontSize: 15),
                              ),
                              Text(
                                'Passenger',
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        _ActionBtn(icon: Icons.phone_outlined, onTap: () {}),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Start Messaging CTA
                    GestureDetector(
                      onTap: () {
                        if (activeRide == null) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              rideId: activeRide.id,
                              otherUserId: activeRide.passenger?['_id'] ??
                                  activeRide.passenger?['id'] ?? '',
                              otherUserName:
                                  '${activeRide.passenger?['firstName'] ?? ''} ${activeRide.passenger?['lastName'] ?? ''}'
                                      .trim(),
                            ),
                          ),
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_outline_rounded,
                                color: AppColors.primary, size: 17),
                            const SizedBox(width: 8),
                            Text(
                              'Start Messaging',
                              style: GoogleFonts.sora(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),

                  if (isPickup) ...[
                    // Arrived button
                    AppButton(
                      label: 'I\'ve Arrived at Pickup',
                      onPressed: () async {
                        await driver.notifyArrived();
                        if (mounted) setState(() {});
                      },
                      backgroundColor: AppColors.warning,
                    ),
                    const SizedBox(height: 12),
                    AppButton(
                      label: 'Start Trip',
                      onPressed: () async {
                        await driver.startTrip();
                        if (mounted) setState(() {});
                      },
                    ),
                  ] else ...[
                    AppButton(
                      label: 'Complete Trip',
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Confirm Payment'),
                            content: Text(
                              'Has the passenger paid FC ${activeRide?.price.toStringAsFixed(0) ?? ''}?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Not Yet'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Yes, Received'),
                              ),
                            ],
                          ),
                        );
                        if (confirmed != true) return;
                        if (!mounted) return;
                        final ok = await driver.completeTrip();
                        if (!mounted) return;
                        if (ok) {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (_) => const RiderHomeScreen()),
                            (r) => false,
                          );
                        }
                      },
                      backgroundColor: AppColors.success,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ActionBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.borderDark),
        ),
        child: Icon(icon, color: AppColors.textOnDark, size: 20),
      ),
    );
  }
}
