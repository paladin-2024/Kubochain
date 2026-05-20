import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../core/constants/app_colors.dart';
import '../../models/ride_model.dart';
import '../../widgets/common/user_avatar.dart';

class RideRequestSheet extends StatefulWidget {
  final RideModel ride;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const RideRequestSheet({
    super.key,
    required this.ride,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  State<RideRequestSheet> createState() => _RideRequestSheetState();
}

class _RideRequestSheetState extends State<RideRequestSheet>
    with SingleTickerProviderStateMixin {
  late Timer _timer;
  int _secondsLeft = 30;
  late AnimationController _progressController;
  late Animation<double> _entryAnim;

  @override
  void initState() {
    super.initState();
    HapticFeedback.heavyImpact();

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..forward();
    _entryAnim = CurvedAnimation(parent: _progressController, curve: const Interval(0, 0.05, curve: Curves.easeOut));

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) {
        t.cancel();
        widget.onDecline();
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _progressController.dispose();
    super.dispose();
  }

  Color get _timerColor => _secondsLeft > 10 ? AppColors.primary : AppColors.error;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 40,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Countdown progress bar ─────────────────────────────────────
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            child: AnimatedBuilder(
              animation: _progressController,
              builder: (_, __) => LinearProgressIndicator(
                value: _progressController.value,
                backgroundColor: AppColors.borderDark,
                valueColor: AlwaysStoppedAnimation<Color>(_timerColor),
                minHeight: 5,
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ─────────────────────────────────────────────
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const HugeIcon(
                        icon: HugeIcons.strokeRoundedNotification01,
                        color: AppColors.success,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'New Ride Request!',
                            style: GoogleFonts.sora(
                              color: AppColors.textOnDark,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                          Text(
                            'Respond quickly',
                            style: GoogleFonts.sora(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Countdown circle
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: _timerColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: _timerColor.withOpacity(0.3), width: 2),
                      ),
                      child: Center(
                        child: Text(
                          '$_secondsLeft',
                          style: GoogleFonts.sora(
                            color: _timerColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                Divider(color: AppColors.borderDark, height: 1),
                const SizedBox(height: 20),

                // ── Passenger info ──────────────────────────────────────
                if (widget.ride.passenger != null)
                  Row(
                    children: [
                      UserAvatar(
                        name: widget.ride.passenger!['firstName'] ?? 'P',
                        imageUrl: widget.ride.passenger!['profileImage'] as String?,
                        radius: 26,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${widget.ride.passenger!['firstName'] ?? ''} ${widget.ride.passenger!['lastName'] ?? ''}',
                              style: GoogleFonts.sora(
                                color: AppColors.textOnDark,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                            Row(
                              children: [
                                const HugeIcon(icon: HugeIcons.strokeRoundedStar, color: AppColors.gold, size: 15),
                                const SizedBox(width: 3),
                                Text(
                                  '${widget.ride.passenger!['rating'] ?? '5.0'}',
                                  style: GoogleFonts.sora(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(50),
                                  ),
                                  child: Text(
                                    'Verified',
                                    style: GoogleFonts.sora(
                                      color: AppColors.success,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 16),

                // ── Route card ──────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F8FF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderDark),
                  ),
                  child: Column(
                    children: [
                      _RouteRow(
                        icon: HugeIcons.strokeRoundedCircle,
                        iconColor: AppColors.primary,
                        label: 'PICKUP',
                        address: widget.ride.pickup.address.split(',').first,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 10, top: 4, bottom: 4),
                        child: Row(
                          children: List.generate(
                            4,
                            (_) => Container(
                              width: 2,
                              height: 5,
                              margin: const EdgeInsets.only(bottom: 4),
                              decoration: BoxDecoration(
                                color: AppColors.textMuted,
                                borderRadius: BorderRadius.circular(1),
                              ),
                            ),
                          ),
                        ),
                      ),
                      _RouteRow(
                        icon: HugeIcons.strokeRoundedMapPin,
                        iconColor: AppColors.error,
                        label: 'DESTINATION',
                        address: widget.ride.destination.address.split(',').first,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ── GPS indicator ───────────────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withOpacity(0.15)),
                  ),
                  child: Row(
                    children: [
                      const HugeIcon(icon: HugeIcons.strokeRoundedGps01, color: AppColors.primary, size: 15),
                      const SizedBox(width: 8),
                      Text(
                        'GPS  ',
                        style: GoogleFonts.sora(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '${widget.ride.pickup.lat.toStringAsFixed(6)}, ${widget.ride.pickup.lng.toStringAsFixed(6)}',
                          style: const TextStyle(
                            color: AppColors.textOnDark,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'LIVE',
                          style: GoogleFonts.sora(
                            color: AppColors.success,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── Stat badges ─────────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: _StatBadge(
                        icon: HugeIcons.strokeRoundedRoute01,
                        value: '${widget.ride.distance.toStringAsFixed(1)} km',
                        label: 'Distance',
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StatBadge(
                        icon: HugeIcons.strokeRoundedMoney01,
                        value: 'FC ${widget.ride.price.toStringAsFixed(0)}',
                        label: 'Fare',
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StatBadge(
                        icon: HugeIcons.strokeRoundedMotorbike01,
                        value: widget.ride.rideType ?? 'Economy',
                        label: 'Type',
                        color: AppColors.orange,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ── Action buttons ──────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          widget.onDecline();
                        },
                        child: Container(
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.error.withOpacity(0.25)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const HugeIcon(icon: HugeIcons.strokeRoundedCancel01, color: AppColors.error, size: 22),
                              const SizedBox(width: 8),
                              Text(
                                'Decline',
                                style: GoogleFonts.sora(
                                  color: AppColors.error,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.heavyImpact();
                          widget.onAccept();
                        },
                        child: Container(
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF10B981), Color(0xFF059669)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.success.withOpacity(0.4),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const HugeIcon(icon: HugeIcons.strokeRoundedCheckmarkCircle01, color: Colors.white, size: 24),
                              const SizedBox(width: 8),
                              Text(
                                'Accept Ride',
                                style: GoogleFonts.sora(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String address;

  const _RouteRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.address,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        HugeIcon(icon: icon, color: iconColor, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.sora(
                  color: AppColors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
              Text(
                address,
                style: GoogleFonts.sora(
                  color: AppColors.textOnDark,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatBadge extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatBadge({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          HugeIcon(icon: icon, color: color, size: 22),
          const SizedBox(height: 5),
          Text(
            value,
            style: GoogleFonts.sora(
              color: AppColors.textOnDark,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
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
