import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/providers.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/user_avatar.dart';
import '../../widgets/map/live_map_widget.dart';
import '../common/chat_screen.dart';
import 'rider_home_screen.dart';

class TripNavigationScreen extends ConsumerStatefulWidget {
  const TripNavigationScreen({super.key});

  @override
  ConsumerState<TripNavigationScreen> createState() => _TripNavigationScreenState();
}

class _TripNavigationScreenState extends ConsumerState<TripNavigationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _cardCtrl;
  late Animation<Offset> _cardSlide;
  late Animation<double> _cardFade;

  @override
  void initState() {
    super.initState();
    _cardCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
    _cardSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOutCubic));
    _cardFade = CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _cardCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final driver = ref.watch(driverProvider);
    final location = ref.watch(locationProvider);
    final activeRide = driver.activeRide;
    final center = location.currentLocation ?? AppConstants.defaultLocation;

    final isPickup = activeRide?.status == 'accepted' || activeRide?.status == 'arriving';
    final destination = isPickup
        ? (activeRide != null ? LatLng(activeRide.pickup.lat, activeRide.pickup.lng) : null)
        : (activeRide != null ? LatLng(activeRide.destination.lat, activeRide.destination.lng) : null);

    return Scaffold(
      body: Stack(
        children: [
          // ── Map ──────────────────────────────────────────────────────────
          LiveMapWidget(
            center: center,
            pickupLocation: location.currentLocation,
            destinationLocation: destination,
          ),

          // ── Top status pill ──────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(50),
                  boxShadow: AppColors.softShadow,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: isPickup ? AppColors.warning : AppColors.success,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (isPickup ? AppColors.warning : AppColors.success).withOpacity(0.5),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (activeRide != null) ...[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            isPickup ? 'Navigate to Pickup' : 'Navigate to Destination',
                            style: GoogleFonts.sora(
                              color: AppColors.textOnDark,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            isPickup
                                ? activeRide.pickup.address.split(',').first
                                : activeRide.destination.address.split(',').first,
                            style: GoogleFonts.sora(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // ── Bottom action card ────────────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SlideTransition(
              position: _cardSlide,
              child: FadeTransition(
                opacity: _cardFade,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                    boxShadow: AppColors.cardShadow,
                  ),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Handle bar
                        Center(
                          child: Container(
                            width: 36,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: AppColors.borderDark,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),

                        if (activeRide?.passenger != null) ...[
                          // Passenger info row
                          Row(
                            children: [
                              UserAvatar(
                                name: activeRide!.passenger!['firstName'] ?? 'P',
                                imageUrl: activeRide.passenger!['profileImage'] as String?,
                                radius: 26,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${activeRide.passenger!['firstName'] ?? ''} ${activeRide.passenger!['lastName'] ?? ''}',
                                      style: GoogleFonts.sora(
                                        color: AppColors.textOnDark,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      'Passenger',
                                      style: GoogleFonts.sora(
                                        color: AppColors.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Phone icon button
                              _CircleIconBtn(
                                icon: HugeIcons.strokeRoundedPhoneCheck,
                                color: AppColors.primary,
                                onTap: () {},
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Message CTA
                          GestureDetector(
                            onTap: () {
                              if (activeRide == null) return;
                              HapticFeedback.lightImpact();
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
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.07),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: AppColors.primary.withOpacity(0.2),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const HugeIcon(icon: HugeIcons.strokeRoundedMessage01,
                                      color: AppColors.primary, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Message Passenger',
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
                        const SizedBox(height: 14),

                        if (isPickup) ...[
                          AppButton(
                            label: "I've Arrived at Pickup",
                            onPressed: () async {
                              await driver.notifyArrived();
                              if (mounted) setState(() {});
                            },
                            backgroundColor: AppColors.warning,
                          ),
                          const SizedBox(height: 10),
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
                                  backgroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  title: Text(
                                    'Confirm Payment',
                                    style: GoogleFonts.sora(
                                      color: AppColors.textOnDark,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  content: Text(
                                    'Has the passenger paid FC ${activeRide?.price.toStringAsFixed(0) ?? ''}?',
                                    style: GoogleFonts.sora(color: AppColors.textSecondary),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, false),
                                      child: Text(
                                        'Not Yet',
                                        style: GoogleFonts.sora(color: AppColors.textSecondary),
                                      ),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.success,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: Text(
                                        'Yes, Received',
                                        style: GoogleFonts.sora(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                              if (confirmed != true) return;
                              if (!mounted) return;
                              final ok = await driver.completeTrip();
                              if (!mounted) return;
                              if (ok) {
                                HapticFeedback.heavyImpact();
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
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleIconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _CircleIconBtn({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: HugeIcon(icon: icon, color: color, size: 22),
      ),
    );
  }
}
