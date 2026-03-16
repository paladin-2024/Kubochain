import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/ride_provider.dart';
import 'driver_arriving_screen.dart';

class SearchingDriverScreen extends StatefulWidget {
  const SearchingDriverScreen({super.key});

  @override
  State<SearchingDriverScreen> createState() => _SearchingDriverScreenState();
}

class _SearchingDriverScreenState extends State<SearchingDriverScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late AnimationController _fadeController;
  late AnimationController _tipController;

  late Animation<double> _pulse1;
  late Animation<double> _pulse2;
  late Animation<double> _pulse3;
  late Animation<double> _rotateDots;
  late Animation<double> _fadeAnim;
  late Animation<double> _tipFade;

  int _tipIndex = 0;
  int _driverCount = 0;

  static const _safetyTips = [
    'Always confirm the plate number\nbefore boarding.',
    'Share your trip details with\na trusted contact.',
    'Your safety rating protects\nevery ride.',
    'All riders are background\nchecked & verified.',
    'SOS button available in-app\nduring your trip.',
  ];

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();

    _tipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();

    _pulse1 = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );
    _pulse2 = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: const Interval(0.2, 0.9, curve: Curves.easeOut),
      ),
    );
    _pulse3 = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );
    _rotateDots = Tween<double>(begin: 0.0, end: 2 * pi).animate(
      CurvedAnimation(parent: _rotateController, curve: Curves.linear),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _tipFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _tipController, curve: Curves.easeOut),
    );

    // Cycle tips
    _cycleTips();

    // Simulated driver count increment
    _simulateDriverCount();

    final ride = context.read<RideProvider>();
    ride.addListener(_onRideStatusChange);
  }

  void _cycleTips() async {
    while (mounted) {
      await Future.delayed(const Duration(seconds: 4));
      if (!mounted) return;
      _tipController.reverse().then((_) {
        if (!mounted) return;
        setState(() => _tipIndex = (_tipIndex + 1) % _safetyTips.length);
        _tipController.forward();
      });
    }
  }

  void _simulateDriverCount() async {
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() => _driverCount = 3 + (DateTime.now().millisecond % 5));
  }

  void _onRideStatusChange() {
    final ride = context.read<RideProvider>();
    if (ride.rideStatus == RideStatus.found && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DriverArrivingScreen()),
      );
    } else if (ride.rideStatus == RideStatus.cancelled && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ride.error ?? 'Ride was cancelled')),
      );
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    _fadeController.dispose();
    _tipController.dispose();
    context.read<RideProvider>().removeListener(_onRideStatusChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ride = context.watch<RideProvider>();

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const SizedBox(height: 32),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    Text(
                      'Finding Your Rider',
                      style: GoogleFonts.sora(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textOnDark,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Connecting you with a nearby boda rider',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.sora(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 48),

              // Pulse animation
              SizedBox(
                width: 260,
                height: 260,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Rings
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (_, __) => Stack(
                        alignment: Alignment.center,
                        children: [
                          _PulseRing(progress: _pulse3.value, baseRadius: 115, color: AppColors.primary, opacity: 0.06),
                          _PulseRing(progress: _pulse2.value, baseRadius: 90, color: AppColors.primary, opacity: 0.10),
                          _PulseRing(progress: _pulse1.value, baseRadius: 70, color: AppColors.primary, opacity: 0.16),
                        ],
                      ),
                    ),

                    // Rotating orbit dots
                    AnimatedBuilder(
                      animation: _rotateDots,
                      builder: (_, __) => SizedBox(
                        width: 200,
                        height: 200,
                        child: CustomPaint(
                          painter: _OrbitDotsPainter(_rotateDots.value),
                        ),
                      ),
                    ),

                    // Core icon
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.primaryGradient,
                        boxShadow: AppColors.primaryGlow,
                      ),
                      child: const Icon(
                        Icons.directions_bike_rounded,
                        color: Colors.white,
                        size: 44,
                      ),
                    ),
                  ],
                ),
              ),

              // Driver count badge
              if (_driverCount > 0) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(
                      color: AppColors.success.withOpacity(0.25),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$_driverCount riders nearby',
                        style: GoogleFonts.sora(
                          color: AppColors.success,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // Ride details card
              if (ride.currentRide != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.cardDark,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.borderDark),
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              _RouteRow(
                                icon: Icons.radio_button_checked,
                                color: AppColors.primary,
                                label: 'Pickup',
                                address: ride.currentRide!.pickup.address,
                              ),
                              const SizedBox(height: 4),
                              Padding(
                                padding: const EdgeInsets.only(left: 10),
                                child: Column(
                                  children: List.generate(
                                    3,
                                    (_) => Padding(
                                      padding:
                                          const EdgeInsets.symmetric(vertical: 2),
                                      child: Container(
                                        width: 2,
                                        height: 6,
                                        color: AppColors.borderDark,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              _RouteRow(
                                icon: Icons.location_on_rounded,
                                color: AppColors.error,
                                label: 'Destination',
                                address: ride.currentRide!.destination.address,
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1, color: AppColors.borderDark),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _StatChip(
                                label: 'Price',
                                value:
                                    'FC ${ride.currentRide!.price.toStringAsFixed(0)}',
                                color: AppColors.success,
                              ),
                              Container(
                                  width: 1,
                                  height: 32,
                                  color: AppColors.borderDark),
                              _StatChip(
                                label: 'Distance',
                                value:
                                    '${ride.currentRide!.distance.toStringAsFixed(1)} km',
                                color: AppColors.primary,
                              ),
                              Container(
                                  width: 1,
                                  height: 32,
                                  color: AppColors.borderDark),
                              _StatChip(
                                label: 'Type',
                                value: ride.currentRide!.rideType == 'premium'
                                    ? 'Premium'
                                    : 'Economy',
                                color: AppColors.gold,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const Spacer(),

              // Safety tip
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: FadeTransition(
                  opacity: _tipFade,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.safetyGold.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: AppColors.safetyGold.withOpacity(0.2)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.shield_outlined,
                            color: AppColors.safetyGold, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Safety Tip',
                                style: GoogleFonts.sora(
                                  color: AppColors.safetyGold,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _safetyTips[_tipIndex],
                                style: GoogleFonts.sora(
                                  color: AppColors.textOnDark.withOpacity(0.8),
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

              const SizedBox(height: 16),

              // Cancel button
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () async {
                          await ride.cancelRide('Changed mind');
                          if (!mounted) return;
                          Navigator.pop(context);
                        },
                        style: OutlinedButton.styleFrom(
                          side:
                              BorderSide(color: AppColors.error.withOpacity(0.5)),
                          foregroundColor: AppColors.error,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          'Cancel Request',
                          style: GoogleFonts.sora(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Pulse Ring ─────────────────────────────────────────────────────────────────
class _PulseRing extends StatelessWidget {
  final double progress;
  final double baseRadius;
  final Color color;
  final double opacity;

  const _PulseRing({
    required this.progress,
    required this.baseRadius,
    required this.color,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    final size = baseRadius * 2 * (0.6 + 0.4 * progress);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(opacity * (1 - progress)),
      ),
    );
  }
}

// ── Orbit Dots Painter ─────────────────────────────────────────────────────────
class _OrbitDotsPainter extends CustomPainter {
  final double angle;
  _OrbitDotsPainter(this.angle);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = size.width / 2 - 8;
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < 6; i++) {
      final a = angle + (i * pi / 3);
      final x = cx + radius * cos(a);
      final y = cy + radius * sin(a);
      final opacity = 0.3 + 0.7 * ((cos(a - angle) + 1) / 2);
      paint.color = AppColors.primary.withOpacity(opacity * 0.6);
      canvas.drawCircle(Offset(x, y), 4.0, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _OrbitDotsPainter old) => old.angle != angle;
}

// ── Route Row ──────────────────────────────────────────────────────────────────
class _RouteRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String address;

  const _RouteRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.address,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.sora(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                address,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.sora(
                  fontSize: 13,
                  color: AppColors.textOnDark,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Stat Chip ──────────────────────────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.sora(
            fontSize: 10,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.sora(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}
