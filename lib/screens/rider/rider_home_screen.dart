import 'dart:ui';
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
import '../../widgets/common/press_scale.dart';
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
  late AnimationController _statsPulseCtrl;
  late Animation<double> _onlineGlow;
  late Animation<double> _cardEntry;
  late Animation<Offset> _cardSlide;
  late Animation<double> _statsPulse;

  @override
  void initState() {
    super.initState();

    _onlineGlowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _cardEntryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();

    _statsPulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _onlineGlow = Tween<double>(begin: 0.3, end: 0.85).animate(
      CurvedAnimation(parent: _onlineGlowCtrl, curve: Curves.easeInOut),
    );
    _cardEntry = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _cardEntryCtrl, curve: AppColors.springEasing),
    );
    _cardSlide = Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero)
        .animate(CurvedAnimation(parent: _cardEntryCtrl, curve: AppColors.springEasing));
    _statsPulse = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _statsPulseCtrl, curve: Curves.easeInOut),
    );

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
    _statsPulseCtrl.dispose();
    ref.read(driverProvider).removeListener(_onDriverStateChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth      = ref.watch(authProvider);
    final driver    = ref.watch(driverProvider);
    final location  = ref.watch(locationProvider);
    final center    = location.currentLocation ?? _defaultCenter;
    final firstName = auth.user?.firstName ?? 'Conducteur';

    return Scaffold(
      body: Stack(
        children: [
          // ── Map (full screen) ──────────────────────────────────────────────
          LiveMapWidget(
            center: center,
            pickupLocation: location.currentLocation,
            mapController: _mapController,
          ),

          // ── Top overlay ────────────────────────────────────────────────────
          Positioned(
            top: 0, left: 0, right: 0,
            child: FadeTransition(
              opacity: _cardEntry,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      // Online/Offline pill
                      _OnlinePill(
                        isOnline: driver.isOnline,
                        glowAnim: _onlineGlow,
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          driver.toggleOnline(!driver.isOnline);
                        },
                      ),
                      const Spacer(),
                      // Avatar pill
                      _AvatarPill(
                        firstName: firstName,
                        imageUrl: auth.user?.profileImage,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Bottom card ────────────────────────────────────────────────────
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: SlideTransition(
              position: _cardSlide,
              child: FadeTransition(
                opacity: _cardEntry,
                child: _BottomCard(
                  firstName: firstName,
                  driver: driver,
                  onlineGlow: _onlineGlow,
                  statsPulse: _statsPulse,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Online Pill ───────────────────────────────────────────────────────────────
class _OnlinePill extends StatelessWidget {
  final bool isOnline;
  final Animation<double> glowAnim;
  final VoidCallback onTap;

  const _OnlinePill({
    required this.isOnline,
    required this.glowAnim,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PressScale(
      scale: 0.93,
      onTap: onTap,
      child: AnimatedBuilder(
        animation: glowAnim,
        builder: (_, __) => ClipRRect(
          borderRadius: BorderRadius.circular(50),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: AppColors.springEasing,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: isOnline
                    ? AppColors.success.withValues(alpha: 0.92)
                    : Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(50),
                border: Border.all(
                  color: isOnline
                      ? AppColors.success.withValues(alpha: 0.5)
                      : AppColors.borderDark,
                  width: 1.2,
                ),
                boxShadow: isOnline
                    ? [
                        BoxShadow(
                          color: AppColors.success.withValues(alpha: glowAnim.value * 0.45),
                          blurRadius: 24,
                          spreadRadius: 2,
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.10),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 8, height: 8,
                    decoration: BoxDecoration(
                      color: isOnline ? Colors.white : AppColors.textMuted,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isOnline ? 'En ligne' : 'Hors ligne',
                    style: GoogleFonts.sora(
                      color: isOnline ? Colors.white : AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Avatar Pill ───────────────────────────────────────────────────────────────
class _AvatarPill extends StatelessWidget {
  final String firstName;
  final String? imageUrl;

  const _AvatarPill({required this.firstName, this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(50),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(50),
            border: Border.all(
              color: AppColors.success.withValues(alpha: 0.18),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              UserAvatar(
                name: firstName,
                imageUrl: imageUrl,
                radius: 15,
                backgroundColor: AvatarPickerSheet.presets[StorageService.getAvatarColorIndex()],
              ),
              const SizedBox(width: 8),
              Text(
                firstName,
                style: GoogleFonts.sora(
                  color: AppColors.textOnDark,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Bottom Card ───────────────────────────────────────────────────────────────
class _BottomCard extends StatelessWidget {
  final String firstName;
  final dynamic driver;
  final Animation<double> onlineGlow;
  final Animation<double> statsPulse;

  const _BottomCard({
    required this.firstName,
    required this.driver,
    required this.onlineGlow,
    required this.statsPulse,
  });

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.97),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border(
              top: BorderSide(
                color: AppColors.success.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.success.withValues(alpha: 0.10),
                blurRadius: 40,
                offset: const Offset(0, -8),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              Padding(
                padding: EdgeInsets.fromLTRB(20, 4, 20, bottom + 96),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Greeting + go-online CTA
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
                              AnimatedBuilder(
                                animation: onlineGlow,
                                builder: (_, __) => Row(
                                  children: [
                                    Container(
                                      width: 8, height: 8,
                                      decoration: BoxDecoration(
                                        color: driver.isOnline
                                            ? AppColors.success
                                            : AppColors.textMuted,
                                        shape: BoxShape.circle,
                                        boxShadow: driver.isOnline
                                            ? [
                                                BoxShadow(
                                                  color: AppColors.success.withValues(
                                                      alpha: onlineGlow.value * 0.7),
                                                  blurRadius: 6,
                                                  spreadRadius: 1,
                                                ),
                                              ]
                                            : [],
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      driver.isOnline
                                          ? 'En attente de demandes…'
                                          : 'Passez en ligne pour commencer',
                                      style: GoogleFonts.sora(
                                        color: driver.isOnline
                                            ? AppColors.success
                                            : AppColors.textSecondary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!driver.isOnline)
                          PressScale(
                            scale: 0.92,
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              driver.toggleOnline(true);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                              decoration: BoxDecoration(
                                gradient: AppColors.riderGradient,
                                borderRadius: BorderRadius.circular(50),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.success.withValues(alpha: 0.40),
                                    blurRadius: 16,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Text(
                                'En ligne',
                                style: GoogleFonts.sora(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Stats row
                    Row(
                      children: [
                        Expanded(
                          child: _StatTile(
                            icon: HugeIcons.strokeRoundedWallet01,
                            label: 'Revenus du jour',
                            value: 'FC ${driver.todayEarnings.toStringAsFixed(0)}',
                            color: AppColors.success,
                            gradient: AppColors.riderGradient,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _StatTile(
                            icon: HugeIcons.strokeRoundedMotorbike01,
                            label: 'Courses du jour',
                            value: '${driver.completedRides.length}',
                            color: AppColors.primary,
                            gradient: AppColors.auroraGradient,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _StatTile(
                            icon: HugeIcons.strokeRoundedStar,
                            label: 'Note',
                            value: '5.0',
                            color: AppColors.gold,
                            gradient: AppColors.safetyGradient,
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
    );
  }
}

// ── Stat Tile ─────────────────────────────────────────────────────────────────
class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final LinearGradient gradient;

  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.12),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: HugeIcon(icon: icon, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.sora(
              color: AppColors.textOnDark,
              fontWeight: FontWeight.w800,
              fontSize: 15,
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
              fontSize: 9.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
