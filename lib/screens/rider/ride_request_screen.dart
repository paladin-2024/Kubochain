import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/ride_model.dart';
import '../../widgets/common/app_button.dart';

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

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..forward();

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

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Countdown bar
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            child: AnimatedBuilder(
              animation: _progressController,
              builder: (_, __) => LinearProgressIndicator(
                value: _progressController.value,
                backgroundColor: AppColors.borderDark,
                valueColor: AlwaysStoppedAnimation<Color>(
                  _secondsLeft > 10 ? AppColors.primary : AppColors.error,
                ),
                minHeight: 4,
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    const Text(
                      'New Ride Request!',
                      style: TextStyle(
                        color: AppColors.textOnDark,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _secondsLeft > 10
                            ? AppColors.primary.withOpacity(0.2)
                            : AppColors.error.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '$_secondsLeft',
                          style: TextStyle(
                            color: _secondsLeft > 10 ? AppColors.primary : AppColors.error,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Passenger info
                if (widget.ride.passenger != null)
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.primary.withOpacity(0.2),
                        child: Text(
                          (widget.ride.passenger!['firstName'] ?? 'P')[0].toUpperCase(),
                          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${widget.ride.passenger!['firstName'] ?? ''} ${widget.ride.passenger!['lastName'] ?? ''}',
                            style: const TextStyle(color: AppColors.textOnDark, fontWeight: FontWeight.w600),
                          ),
                          Row(
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                '${widget.ride.passenger!['rating'] ?? 5.0}',
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                const SizedBox(height: 20),

                // Route
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardDark,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderDark),
                  ),
                  child: Column(
                    children: [
                      _RouteRow(
                        icon: Icons.my_location,
                        iconColor: AppColors.primary,
                        label: 'Pickup',
                        address: widget.ride.pickup.address.split(',').first,
                      ),
                      const Padding(
                        padding: EdgeInsets.only(left: 9, top: 4, bottom: 4),
                        child: SizedBox(
                          width: 2,
                          height: 16,
                          child: DecoratedBox(decoration: BoxDecoration(color: AppColors.borderDark)),
                        ),
                      ),
                      _RouteRow(
                        icon: Icons.location_on,
                        iconColor: AppColors.error,
                        label: 'Destination',
                        address: widget.ride.destination.address.split(',').first,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // GPS coordinates — rider can confirm exact pickup point
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.gps_fixed, color: AppColors.primary, size: 15),
                      const SizedBox(width: 8),
                      Text(
                        'GPS ',
                        style: TextStyle(
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
                          color: AppColors.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'LIVE',
                          style: TextStyle(
                            color: AppColors.primary,
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

                // Stats
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatBadge(
                      icon: Icons.route,
                      value: '${widget.ride.distance.toStringAsFixed(1)} km',
                      color: AppColors.primary,
                    ),
                    _StatBadge(
                      icon: Icons.monetization_on_outlined,
                      value: 'FC ${widget.ride.price.toStringAsFixed(0)}',
                      color: AppColors.success,
                    ),
                    _StatBadge(
                      icon: Icons.directions_bike,
                      value: widget.ride.rideType ?? 'Economy',
                      color: AppColors.orange,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: 'Decline',
                        onPressed: widget.onDecline,
                        isOutlined: true,
                        backgroundColor: AppColors.error,
                        textColor: AppColors.error,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppButton(
                        label: 'Accept',
                        onPressed: widget.onAccept,
                        backgroundColor: AppColors.success,
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

  const _RouteRow({required this.icon, required this.iconColor, required this.label, required this.address});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
              Text(address, style: const TextStyle(color: AppColors.textOnDark, fontWeight: FontWeight.w500, fontSize: 13)),
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
  final Color color;

  const _StatBadge({required this.icon, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
        ],
      ),
    );
  }
}
