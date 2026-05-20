import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/ride_provider.dart';
import '../../providers/providers.dart';
import 'driver_arriving_screen.dart';

class SearchingDriverScreen extends ConsumerStatefulWidget {
  const SearchingDriverScreen({super.key});

  @override
  ConsumerState<SearchingDriverScreen> createState() => _SearchingDriverScreenState();
}

class _SearchingDriverScreenState extends ConsumerState<SearchingDriverScreen>
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
    'Vérifiez toujours la plaque d\'immatriculation\navant de monter.',
    'Partagez les détails de votre trajet\navec un contact de confiance.',
    'Votre note de sécurité protège\nchaque trajet.',
    'Tous les conducteurs sont vérifiés\net approuvés.',
    'Bouton SOS disponible dans l\'appli\npendant votre trajet.',
  ];

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
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
      CurvedAnimation(parent: _pulseController, curve: const Interval(0.0, 0.7, curve: Curves.easeOut)),
    );
    _pulse2 = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: const Interval(0.2, 0.9, curve: Curves.easeOut)),
    );
    _pulse3 = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: const Interval(0.4, 1.0, curve: Curves.easeOut)),
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

    _cycleTips();
    _simulateDriverCount();

    final ride = ref.read(rideProvider);
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
    final ride = ref.read(rideProvider);
    if (ride.rideStatus == RideStatus.found && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DriverArrivingScreen()),
      );
    } else if (ride.rideStatus == RideStatus.cancelled && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ride.error ?? 'Trajet annulé')),
      );
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    _fadeController.dispose();
    _tipController.dispose();
    ref.read(rideProvider).removeListener(_onRideStatusChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ride = ref.watch(rideProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FF),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const SizedBox(height: 28),

              // ── Header ───────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    Text(
                      'Recherche d\'un conducteur',
                      style: GoogleFonts.sora(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textOnDark,
                        letterSpacing: -0.7,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Connexion avec un conducteur boda à proximité',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.sora(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 44),

              // ── Pulse animation ──────────────────────────────────────────
              SizedBox(
                width: 280,
                height: 280,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (_, __) => Stack(
                        alignment: Alignment.center,
                        children: [
                          _PulseRing(
                            progress: _pulse3.value,
                            baseRadius: 120,
                            color: AppColors.primary,
                            opacity: 0.05,
                          ),
                          _PulseRing(
                            progress: _pulse2.value,
                            baseRadius: 94,
                            color: AppColors.primary,
                            opacity: 0.09,
                          ),
                          _PulseRing(
                            progress: _pulse1.value,
                            baseRadius: 72,
                            color: AppColors.primary,
                            opacity: 0.14,
                          ),
                        ],
                      ),
                    ),

                    AnimatedBuilder(
                      animation: _rotateDots,
                      builder: (_, __) => SizedBox(
                        width: 210,
                        height: 210,
                        child: CustomPaint(
                          painter: _OrbitDotsPainter(_rotateDots.value),
                        ),
                      ),
                    ),

                    // Core icon — huge and impactful
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.4),
                            blurRadius: 28,
                            spreadRadius: 0,
                          ),
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.15),
                            blurRadius: 50,
                            spreadRadius: 8,
                          ),
                        ],
                      ),
                      child: const HugeIcon(
                        icon: HugeIcons.strokeRoundedMotorbike01,
                        color: Colors.white,
                        size: 50,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Drivers nearby badge ──────────────────────────────────────
              if (_driverCount > 0) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(color: AppColors.success.withOpacity(0.2)),
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
                        '$_driverCount conducteurs à proximité',
                        style: GoogleFonts.sora(
                          color: AppColors.success,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // ── Ride details card ─────────────────────────────────────────
              if (ride.currentRide != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: AppColors.cardShadow,
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            children: [
                              _RouteRow(
                                icon: HugeIcons.strokeRoundedCircle,
                                color: AppColors.primary,
                                label: 'DÉPART',
                                address: ride.currentRide!.pickup.address,
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 11, top: 4, bottom: 4),
                                child: Column(
                                  children: List.generate(
                                    3,
                                    (_) => Container(
                                      width: 2,
                                      height: 6,
                                      margin: const EdgeInsets.only(bottom: 3),
                                      color: AppColors.borderDark,
                                    ),
                                  ),
                                ),
                              ),
                              _RouteRow(
                                icon: HugeIcons.strokeRoundedMapPin,
                                color: AppColors.error,
                                label: 'ARRIVÉE',
                                address: ride.currentRide!.destination.address,
                              ),
                            ],
                          ),
                        ),
                        Divider(height: 1, color: AppColors.borderDark),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _StatChip(
                                label: 'Prix',
                                value: 'FC ${ride.currentRide!.price.toStringAsFixed(0)}',
                                color: AppColors.success,
                                icon: HugeIcons.strokeRoundedMoney01,
                              ),
                              Container(width: 1, height: 36, color: AppColors.borderDark),
                              _StatChip(
                                label: 'Distance',
                                value: '${ride.currentRide!.distance.toStringAsFixed(1)} km',
                                color: AppColors.primary,
                                icon: HugeIcons.strokeRoundedRoute01,
                              ),
                              Container(width: 1, height: 36, color: AppColors.borderDark),
                              _StatChip(
                                label: 'Type',
                                value: ride.currentRide!.rideType == 'premium' ? 'Premium' : 'Économique',
                                color: AppColors.gold,
                                icon: HugeIcons.strokeRoundedMotorbike01,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const Spacer(),

              // ── Safety tip ─────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: FadeTransition(
                  opacity: _tipFade,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.warning.withOpacity(0.18)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.warning.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const HugeIcon(
                            icon: HugeIcons.strokeRoundedShieldUser,
                            color: AppColors.warning,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Conseil de sécurité',
                                style: GoogleFonts.sora(
                                  color: AppColors.warning,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                _safetyTips[_tipIndex],
                                style: GoogleFonts.sora(
                                  color: AppColors.textOnDark,
                                  fontSize: 13,
                                  height: 1.4,
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

              const SizedBox(height: 12),

              // ── Cancel button ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () async {
                          HapticFeedback.lightImpact();
                          await ride.cancelRide('Changed mind');
                          if (!mounted) return;
                          Navigator.pop(context);
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppColors.error.withOpacity(0.4), width: 1.5),
                          foregroundColor: AppColors.error,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: Text(
                          'Annuler la demande',
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

// ── Orbit Dots ─────────────────────────────────────────────────────────────────
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
      final opacity = 0.2 + 0.8 * ((cos(a - angle) + 1) / 2);
      paint.color = AppColors.primary.withOpacity(opacity * 0.5);
      canvas.drawCircle(Offset(x, y), 5.0, paint);
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
        HugeIcon(icon: icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.sora(
                  fontSize: 10,
                  color: AppColors.textMuted,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                address,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.sora(
                  fontSize: 13,
                  color: AppColors.textOnDark,
                  fontWeight: FontWeight.w600,
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
  final IconData icon;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        HugeIcon(icon: icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.sora(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textOnDark,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.sora(
            fontSize: 10,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
