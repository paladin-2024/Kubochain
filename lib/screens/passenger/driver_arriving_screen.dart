import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/ride_provider.dart';
import '../../widgets/map/live_map_widget.dart';
import '../common/chat_screen.dart';
import 'trip_screen.dart';

class DriverArrivingScreen extends StatefulWidget {
  const DriverArrivingScreen({super.key});

  @override
  State<DriverArrivingScreen> createState() => _DriverArrivingScreenState();
}

class _DriverArrivingScreenState extends State<DriverArrivingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    context.read<RideProvider>().addListener(_onStatusChange);
  }

  void _onStatusChange() {
    final ride = context.read<RideProvider>();
    if (ride.rideStatus == RideStatus.inProgress && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const TripScreen()),
      );
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    context.read<RideProvider>().removeListener(_onStatusChange);
    super.dispose();
  }

  int _calcEtaMinutes(LatLng from, LatLng to) {
    const R = 6371.0;
    final dLat = (to.latitude - from.latitude) * pi / 180;
    final dLon = (to.longitude - from.longitude) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(from.latitude * pi / 180) *
            cos(to.latitude * pi / 180) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    final distKm = R * c;
    return (distKm / 0.5).ceil().clamp(1, 60);
  }

  @override
  Widget build(BuildContext context) {
    final ride = context.watch<RideProvider>();
    final currentRide = ride.currentRide;
    final driverLocation = ride.driverLocation;
    final center = driverLocation ??
        (currentRide != null
            ? LatLng(currentRide.pickup.lat, currentRide.pickup.lng)
            : AppConstants.defaultLocation);

    final driver = currentRide?.driver;
    final isArrived = ride.rideStatus == RideStatus.arriving;

    final etaMinutes = driverLocation != null && currentRide != null
        ? _calcEtaMinutes(
            driverLocation,
            LatLng(currentRide.pickup.lat, currentRide.pickup.lng))
        : ride.driverEta;

    return Scaffold(
      body: Stack(
        children: [
          // Map
          LiveMapWidget(
            center: center,
            pickupLocation: currentRide != null
                ? LatLng(currentRide.pickup.lat, currentRide.pickup.lng)
                : null,
            driverLocation: driverLocation,
          ),

          // ETA pill at top
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 0,
            right: 0,
            child: Center(
              child: AnimatedBuilder(
                animation: _pulseAnim,
                builder: (_, __) => Transform.scale(
                  scale: isArrived ? 1.0 : _pulseAnim.value,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: isArrived
                          ? AppColors.success.withOpacity(0.95)
                          : AppColors.backgroundMid.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(
                        color: isArrived
                            ? AppColors.success.withOpacity(0.3)
                            : AppColors.borderDark,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (isArrived ? AppColors.success : AppColors.primary)
                              .withOpacity(0.25),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isArrived
                              ? Icons.check_circle_rounded
                              : Icons.directions_bike_rounded,
                          color: isArrived ? Colors.white : AppColors.primary,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isArrived
                              ? 'Driver Arrived!'
                              : etaMinutes > 0
                                  ? '$etaMinutes min away'
                                  : 'On the way...',
                          style: GoogleFonts.sora(
                            color: isArrived
                                ? Colors.white
                                : AppColors.textOnDark,
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
                        20, 4, 20, MediaQuery.of(context).padding.bottom + 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Driver info row
                        if (driver != null) ...[
                          Row(
                            children: [
                              // Avatar
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: AppColors.primaryGradient,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withOpacity(0.3),
                                      blurRadius: 12,
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: driver['profileImage'] != null
                                      ? Image.network(driver['profileImage'],
                                          fit: BoxFit.cover)
                                      : Center(
                                          child: Text(
                                            (driver['firstName'] ?? 'D')[0]
                                                .toUpperCase(),
                                            style: GoogleFonts.sora(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 22,
                                            ),
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${driver['firstName'] ?? ''} ${driver['lastName'] ?? ''}',
                                      style: GoogleFonts.sora(
                                        color: AppColors.textOnDark,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 17,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.star_rounded,
                                            color: AppColors.gold, size: 14),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${driver['rating'] ?? 5.0}',
                                          style: GoogleFonts.sora(
                                            color: AppColors.textSecondary,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        const Icon(Icons.shield_rounded,
                                            color: AppColors.success, size: 14),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Verified',
                                          style: GoogleFonts.sora(
                                            color: AppColors.success,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              // Action buttons
                              _CircleBtn(
                                icon: Icons.message_rounded,
                                onTap: currentRide != null
                                    ? () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => ChatScreen(
                                              rideId: currentRide.id,
                                              otherUserId: driver['userId'] ??
                                                  driver['id'] ??
                                                  '',
                                              otherUserName:
                                                  '${driver['firstName'] ?? ''} ${driver['lastName'] ?? ''}'
                                                      .trim(),
                                              otherUserPhoto:
                                                  driver['profileImage'],
                                            ),
                                          ),
                                        )
                                    : null,
                              ),
                              const SizedBox(width: 8),
                              _CircleBtn(
                                icon: Icons.phone_rounded,
                                onTap: () {},
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Vehicle card
                        if (currentRide?.driver?['vehicle'] != null) ...[
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.cardDark,
                              borderRadius: BorderRadius.circular(16),
                              border:
                                  Border.all(color: AppColors.borderDark),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                      Icons.directions_bike_rounded,
                                      color: AppColors.primary,
                                      size: 22),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${currentRide!.driver!['vehicle']['color'] ?? ''} ${currentRide.driver!['vehicle']['make'] ?? ''}'
                                            .trim(),
                                        style: GoogleFonts.sora(
                                          color: AppColors.textOnDark,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        currentRide.driver!['vehicle']
                                                ['model'] ??
                                            '',
                                        style: GoogleFonts.sora(
                                          color: AppColors.textSecondary,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Plate number
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.backgroundDark,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: AppColors.borderDark),
                                  ),
                                  child: Text(
                                    currentRide.driver!['vehicle']
                                            ['plateNumber'] ??
                                        '',
                                    style: GoogleFonts.sora(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                      color: AppColors.textOnDark,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],

                        // Safety reminder
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.safetyGold.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: AppColors.safetyGold.withOpacity(0.2)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.shield_outlined,
                                  color: AppColors.safetyGold, size: 16),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Confirm the plate number before boarding.',
                                  style: GoogleFonts.sora(
                                    color: AppColors.textOnDark.withOpacity(0.7),
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Start Messaging CTA
                        if (driver != null && currentRide != null)
                          GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatScreen(
                                  rideId: currentRide.id,
                                  otherUserId: driver['userId'] ??
                                      driver['id'] ?? '',
                                  otherUserName:
                                      '${driver['firstName'] ?? ''} ${driver['lastName'] ?? ''}'
                                          .trim(),
                                  otherUserPhoto: driver['profileImage'],
                                ),
                              ),
                            ),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                gradient: AppColors.primaryGradient,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.35),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.chat_bubble_rounded,
                                      color: Colors.white, size: 18),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Start Messaging',
                                    style: GoogleFonts.sora(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
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

// ── Circle Button ──────────────────────────────────────────────────────────────
class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _CircleBtn({required this.icon, this.onTap});

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
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
    );
  }
}
