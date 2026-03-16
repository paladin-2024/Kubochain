import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/driver_provider.dart';
import '../../providers/location_provider.dart';
import '../../widgets/map/live_map_widget.dart';
import 'ride_request_screen.dart';
import 'trip_navigation_screen.dart';

class RiderHomeScreen extends StatefulWidget {
  const RiderHomeScreen({super.key});

  @override
  State<RiderHomeScreen> createState() => _RiderHomeScreenState();
}

class _RiderHomeScreenState extends State<RiderHomeScreen>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  static const LatLng _defaultCenter = AppConstants.defaultLocation;

  late AnimationController _onlineGlowCtrl;
  late Animation<double> _onlineGlow;

  @override
  void initState() {
    super.initState();

    _onlineGlowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _onlineGlow = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _onlineGlowCtrl, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LocationProvider>().init();
      context.read<DriverProvider>().addListener(_onDriverStateChange);
    });
  }

  void _onDriverStateChange() {
    final driver = context.read<DriverProvider>();
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
                MaterialPageRoute(
                    builder: (_) => const TripNavigationScreen()),
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
    context.read<DriverProvider>().removeListener(_onDriverStateChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final driver = context.watch<DriverProvider>();
    final location = context.watch<LocationProvider>();
    final center = location.currentLocation ?? _defaultCenter;
    final firstName = auth.user?.firstName ?? 'Driver';

    return Scaffold(
      body: Stack(
        children: [
          // Map
          LiveMapWidget(
            center: center,
            pickupLocation: location.currentLocation,
            mapController: _mapController,
            isDark: true,
          ),

          // Top controls
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    // Online/Offline toggle
                    GestureDetector(
                      onTap: () => driver.toggleOnline(!driver.isOnline),
                      child: AnimatedBuilder(
                        animation: _onlineGlow,
                        builder: (_, __) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: driver.isOnline
                                ? AppColors.success
                                : AppColors.cardDark,
                            borderRadius: BorderRadius.circular(50),
                            border: Border.all(
                              color: driver.isOnline
                                  ? AppColors.success.withOpacity(0.5)
                                  : AppColors.borderDark,
                            ),
                            boxShadow: driver.isOnline
                                ? [
                                    BoxShadow(
                                      color: AppColors.success
                                          .withOpacity(_onlineGlow.value * 0.5),
                                      blurRadius: 20,
                                      spreadRadius: 2,
                                    ),
                                  ]
                                : [],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: driver.isOnline
                                      ? Colors.white
                                      : AppColors.textSecondary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                driver.isOnline ? 'Online' : 'Offline',
                                style: GoogleFonts.sora(
                                  color: driver.isOnline
                                      ? Colors.white
                                      : AppColors.textSecondary,
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
                    // Avatar pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.cardDark.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(color: AppColors.borderDark),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor:
                                AppColors.success.withOpacity(0.2),
                            child: Text(
                              firstName[0].toUpperCase(),
                              style: GoogleFonts.sora(
                                color: AppColors.success,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
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

          // Go Online FAB (when offline)
          if (!driver.isOnline)
            Positioned(
              bottom: 220,
              right: 16,
              child: GestureDetector(
                onTap: () => driver.toggleOnline(true),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: AppColors.successGradient,
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.success.withOpacity(0.4),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.power_settings_new_rounded,
                          color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Go Online',
                        style: GoogleFonts.sora(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Bottom card
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(color: Colors.black54, blurRadius: 20),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      width: 40,
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
                        MediaQuery.of(context).padding.bottom + 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Greeting + status line
                        Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hello, $firstName!',
                                  style: GoogleFonts.sora(
                                    color: AppColors.textOnDark,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  driver.isOnline
                                      ? 'Waiting for ride requests...'
                                      : 'Go online to start earning',
                                  style: GoogleFonts.sora(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            // Status dot
                            AnimatedBuilder(
                              animation: _onlineGlow,
                              builder: (_, __) => Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: driver.isOnline
                                      ? AppColors.success
                                      : AppColors.textSecondary,
                                  shape: BoxShape.circle,
                                  boxShadow: driver.isOnline
                                      ? [
                                          BoxShadow(
                                            color: AppColors.success
                                                .withOpacity(_onlineGlow.value),
                                            blurRadius: 8,
                                            spreadRadius: 2,
                                          ),
                                        ]
                                      : [],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Stats row
                        Row(
                          children: [
                            Expanded(
                              child: _StatTile(
                                icon: Icons.account_balance_wallet_rounded,
                                label: "Today's Earnings",
                                value:
                                    'FC ${driver.todayEarnings.toStringAsFixed(0)}',
                                color: AppColors.success,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatTile(
                                icon: Icons.electric_moped_rounded,
                                label: 'Trips Today',
                                value:
                                    '${driver.completedRides.length}',
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatTile(
                                icon: Icons.star_rounded,
                                label: 'Rating',
                                value: '5.0',
                                color: AppColors.gold,
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

  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.sora(
              color: AppColors.textOnDark,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: GoogleFonts.sora(
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
