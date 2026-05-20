import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:latlong2/latlong.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/storage_service.dart';
import '../../providers/providers.dart';
import '../../widgets/common/avatar_picker_sheet.dart';
import '../../widgets/common/user_avatar.dart';
import '../../widgets/map/live_map_widget.dart';
import 'ride_request_screen.dart';
import 'trip_navigation_screen.dart';

class RiderHomeScreen extends ConsumerStatefulWidget {
  const RiderHomeScreen({super.key});

  @override
  ConsumerState<RiderHomeScreen> createState() => _RiderHomeScreenState();
}

class _RiderHomeScreenState extends ConsumerState<RiderHomeScreen>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  static const LatLng _defaultCenter = AppConstants.defaultLocation;

  late AnimationController _onlineGlowCtrl;
  late AnimationController _cardEntryCtrl;
  late Animation<double> _onlineGlow;
  late Animation<double> _cardEntry;
  late Animation<Offset> _cardSlide;

  @override
  void initState() {
    super.initState();

    _onlineGlowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _cardEntryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    _onlineGlow = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _onlineGlowCtrl, curve: Curves.easeInOut),
    );
    _cardEntry = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _cardEntryCtrl, curve: Curves.easeOutCubic),
    );
    _cardSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _cardEntryCtrl, curve: Curves.easeOutCubic));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(locationProvider).init();
      ref.read(driverProvider).addListener(_onDriverStateChange);

      final pending = NotificationService.consumePendingNotification();
      if (pending != null && pending['type'] == 'new_ride_request') {
        final rideId = pending['rideId'] as String?;
        if (rideId != null) ref.read(driverProvider).loadRideFromNotification(rideId);
      }
    });
  }

  void _onDriverStateChange() {
    final driver = ref.read(driverProvider);
    if (driver.pendingRequest != null && mounted) {
      showModalBottomSheet(
        context: context,
        isDismissible: false,
        enableDrag: false,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => RideRequestSheet(
          ride: driver.pendingRequest!,
          onAccept: () async {
            Navigator.pop(context);
            final ok = await driver.acceptRide();
            if (ok && mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TripNavigationScreen()),
              );
            }
          },
          onDecline: () {
            Navigator.pop(context);
            driver.declineRequest();
          },
        ),
      );
    }
    if (driver.activeRide != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const TripNavigationScreen()),
      );
    }
  }

  @override
  void dispose() {
    _onlineGlowCtrl.dispose();
    _cardEntryCtrl.dispose();
    ref.read(driverProvider).removeListener(_onDriverStateChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final driver = ref.watch(driverProvider);
    final location = ref.watch(locationProvider);
    final center = location.currentLocation ?? _defaultCenter;
    final firstName = auth.user?.firstName ?? 'Conducteur';

    return Scaffold(
      body: Stack(
        children: [
          // ── Map ────────────────────────────────────────────────────────────
          LiveMapWidget(
            center: center,
            pickupLocation: location.currentLocation,
            mapController: _mapController,
          ),

          // ── Top overlay bar ────────────────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    // Online/Offline pill toggle
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        driver.toggleOnline(!driver.isOnline);
                      },
                      child: AnimatedBuilder(
                        animation: _onlineGlow,
                        builder: (_, __) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                          decoration: BoxDecoration(
                            color: driver.isOnline ? AppColors.success : Colors.white,
                            borderRadius: BorderRadius.circular(50),
                            border: Border.all(
                              color: driver.isOnline
                                  ? AppColors.success
                                  : AppColors.borderDark,
                              width: 1.5,
                            ),
                            boxShadow: driver.isOnline
                                ? [
                                    BoxShadow(
                                      color: AppColors.success.withOpacity(_onlineGlow.value * 0.5),
                                      blurRadius: 20,
                                      spreadRadius: 2,
                                    ),
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.08),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ]
                                : [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.08),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 9,
                                height: 9,
                                decoration: BoxDecoration(
                                  color: driver.isOnline ? Colors.white : AppColors.textMuted,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                driver.isOnline ? 'En ligne' : 'Hors ligne',
                                style: GoogleFonts.sora(
                                  color: driver.isOnline ? Colors.white : AppColors.textSecondary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const Spacer(),

                    // Driver avatar pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(50),
                        boxShadow: AppColors.softShadow,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          UserAvatar(
                            name: firstName,
                            imageUrl: auth.user?.profileImage,
                            radius: 15,
                            backgroundColor: AvatarPickerSheet.presets[StorageService.getAvatarColorIndex()],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            firstName,
                            style: GoogleFonts.sora(
                              color: AppColors.textOnDark,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Bottom info card ───────────────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SlideTransition(
              position: _cardSlide,
              child: FadeTransition(
                opacity: _cardEntry,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                    boxShadow: AppColors.cardShadow,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Handle bar
                      Center(
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 10),
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.borderDark,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),

                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          20, 4, 20,
                          MediaQuery.of(context).padding.bottom + 90,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Greeting + status row
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Bonjour, $firstName !',
                                        style: GoogleFonts.sora(
                                          color: AppColors.textOnDark,
                                          fontSize: 22,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          AnimatedBuilder(
                                            animation: _onlineGlow,
                                            builder: (_, __) => Container(
                                              width: 8,
                                              height: 8,
                                              decoration: BoxDecoration(
                                                color: driver.isOnline
                                                    ? AppColors.success
                                                    : AppColors.textMuted,
                                                shape: BoxShape.circle,
                                                boxShadow: driver.isOnline
                                                    ? [
                                                        BoxShadow(
                                                          color: AppColors.success.withOpacity(_onlineGlow.value * 0.7),
                                                          blurRadius: 6,
                                                          spreadRadius: 1,
                                                        ),
                                                      ]
                                                    : [],
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            driver.isOnline
                                                ? 'En attente de demandes de courses…'
                                                : 'Passez en ligne pour commencer',
                                            style: GoogleFonts.sora(
                                              color: AppColors.textSecondary,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                // Quick go-online CTA if offline
                                if (!driver.isOnline)
                                  GestureDetector(
                                    onTap: () {
                                      HapticFeedback.mediumImpact();
                                      driver.toggleOnline(true);
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFF10B981), Color(0xFF059669)],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(50),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.success.withOpacity(0.4),
                                            blurRadius: 14,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        'En ligne',
                                        style: GoogleFonts.sora(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            // Stats row — huge icons
                            Row(
                              children: [
                                Expanded(
                                  child: _StatTile(
                                    icon: HugeIcons.strokeRoundedWallet01,
                                    label: 'Revenus du jour',
                                    value: 'FC ${driver.todayEarnings.toStringAsFixed(0)}',
                                    color: AppColors.success,
                                    bgColor: const Color(0xFFECFDF5),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _StatTile(
                                    icon: HugeIcons.strokeRoundedMotorbike01,
                                    label: 'Courses du jour',
                                    value: '${driver.completedRides.length}',
                                    color: AppColors.primary,
                                    bgColor: const Color(0xFFEFF6FF),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _StatTile(
                                    icon: HugeIcons.strokeRoundedStar,
                                    label: 'Note',
                                    value: '5.0',
                                    color: AppColors.gold,
                                    bgColor: const Color(0xFFFFFBEB),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
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

// ── Stat Tile ─────────────────────────────────────────────────────────────────
class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final Color bgColor;

  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.12), width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: HugeIcon(icon: icon, color: color, size: 26),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.sora(
              color: AppColors.textOnDark,
              fontWeight: FontWeight.w800,
              fontSize: 16,
              letterSpacing: -0.3,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.sora(
              color: AppColors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
