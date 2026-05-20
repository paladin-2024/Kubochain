import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import 'driver_arriving_screen.dart';
import '../passenger/passenger_main.dart';

class BookingSuccessScreen extends StatefulWidget {
  final String rideId;
  final String pickup;
  final String destination;

  const BookingSuccessScreen({
    super.key,
    required this.rideId,
    required this.pickup,
    required this.destination,
  });

  @override
  State<BookingSuccessScreen> createState() => _BookingSuccessScreenState();
}

class _BookingSuccessScreenState extends State<BookingSuccessScreen>
    with TickerProviderStateMixin {
  late AnimationController _checkCtrl;
  late AnimationController _contentCtrl;
  late AnimationController _particleCtrl;

  late Animation<double> _ringScale;
  late Animation<double> _ringOpacity;
  late Animation<double> _checkScale;
  late Animation<double> _checkDraw;
  late Animation<double> _contentFade;
  late Animation<Offset> _contentSlide;
  late Animation<double> _ctaFade;

  @override
  void initState() {
    super.initState();
    HapticFeedback.heavyImpact();

    _checkCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _contentCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _particleCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))
      ..repeat();

    _ringScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _checkCtrl, curve: const Interval(0.0, 0.5, curve: Curves.elasticOut)),
    );
    _ringOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _checkCtrl, curve: const Interval(0.5, 0.9, curve: Curves.easeOut)),
    );
    _checkScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _checkCtrl, curve: const Interval(0.25, 0.75, curve: Curves.elasticOut)),
    );
    _checkDraw = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _checkCtrl, curve: const Interval(0.45, 0.85, curve: Curves.easeOutCubic)),
    );
    _contentFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _contentCtrl, curve: const Interval(0.0, 0.7, curve: Curves.easeOut)),
    );
    _contentSlide = Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero).animate(
      CurvedAnimation(parent: _contentCtrl, curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic)),
    );
    _ctaFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _contentCtrl, curve: const Interval(0.5, 1.0, curve: Curves.easeOut)),
    );

    _checkCtrl.forward();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _contentCtrl.forward();
    });
  }

  @override
  void dispose() {
    _checkCtrl.dispose();
    _contentCtrl.dispose();
    _particleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FF),
      body: Stack(
        children: [
          // Animated particles background
          AnimatedBuilder(
            animation: _particleCtrl,
            builder: (_, __) => CustomPaint(
              size: size,
              painter: _ParticlePainter(_particleCtrl.value),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                const Spacer(),

                // Check circle with ripple
                SizedBox(
                  height: 200,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Ripple ring
                      AnimatedBuilder(
                        animation: _checkCtrl,
                        builder: (_, __) => Opacity(
                          opacity: _ringOpacity.value,
                          child: Transform.scale(
                            scale: _ringScale.value * 1.8,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.success.withOpacity(0.3),
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Outer ring
                      AnimatedBuilder(
                        animation: _checkCtrl,
                        builder: (_, __) => Opacity(
                          opacity: _ringOpacity.value * 0.6,
                          child: Transform.scale(
                            scale: _ringScale.value * 2.4,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.success.withOpacity(0.15),
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Main circle with check
                      ScaleTransition(
                        scale: _checkScale,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF10B981), Color(0xFF059669)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.success.withOpacity(0.4),
                                blurRadius: 32,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: AnimatedBuilder(
                            animation: _checkDraw,
                            builder: (_, __) => CustomPaint(
                              painter: _CheckPainter(_checkDraw.value),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Title & subtitle
                SlideTransition(
                  position: _contentSlide,
                  child: FadeTransition(
                    opacity: _contentFade,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        children: [
                          Text(
                            'Booking Confirmed!',
                            style: GoogleFonts.sora(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              height: 1.1,
                              letterSpacing: -0.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Your ride is locked in. A driver\nwill be assigned shortly.',
                            style: GoogleFonts.dmSans(
                              fontSize: 15,
                              color: AppColors.textSecondary,
                              height: 1.6,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Trip summary card
                SlideTransition(
                  position: _contentSlide,
                  child: FadeTransition(
                    opacity: _contentFade,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: AppColors.cardShadow,
                        ),
                        child: Column(
                          children: [
                            _RouteRow(
                              icon: HugeIcons.strokeRoundedCircle,
                              color: AppColors.primary,
                              label: 'From',
                              value: widget.pickup,
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 11),
                              child: Column(
                                children: List.generate(3, (_) => Container(
                                  width: 2,
                                  height: 6,
                                  margin: const EdgeInsets.symmetric(vertical: 2),
                                  color: AppColors.border,
                                )),
                              ),
                            ),
                            _RouteRow(
                              icon: HugeIcons.strokeRoundedMapPin,
                              color: AppColors.orange,
                              label: 'To',
                              value: widget.destination,
                            ),
                            const Divider(height: 24, color: AppColors.border),
                            Row(
                              children: [
                                _InfoChip(
                                  icon: HugeIcons.strokeRoundedTag01,
                                  label: 'ID: ${widget.rideId.length > 8 ? widget.rideId.substring(0, 8).toUpperCase() : widget.rideId.toUpperCase()}',
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 8),
                                _InfoChip(
                                  icon: HugeIcons.strokeRoundedClock01,
                                  label: 'ETA ~5 min',
                                  color: AppColors.success,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const Spacer(),

                // CTAs
                FadeTransition(
                  opacity: _ctaFade,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(24, 0, 24, MediaQuery.of(context).padding.bottom + 24),
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () {
                              HapticFeedback.mediumImpact();
                              Navigator.pushAndRemoveUntil(
                                context,
                                PageRouteBuilder(
                                  transitionDuration: const Duration(milliseconds: 400),
                                  pageBuilder: (_, __, ___) => const DriverArrivingScreen(),
                                  transitionsBuilder: (_, anim, __, child) =>
                                      FadeTransition(opacity: anim, child: child),
                                ),
                                (r) => false,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50),
                              ),
                              shadowColor: AppColors.primary.withOpacity(0.4),
                            ).copyWith(
                              elevation: WidgetStateProperty.all(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const HugeIcon(icon: HugeIcons.strokeRoundedNavigation01, color: Colors.white, size: 20),
                                const SizedBox(width: 10),
                                Text(
                                  'Track My Driver',
                                  style: GoogleFonts.sora(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: TextButton(
                            onPressed: () {
                              HapticFeedback.selectionClick();
                              Navigator.pushAndRemoveUntil(
                                context,
                                PageRouteBuilder(
                                  transitionDuration: const Duration(milliseconds: 350),
                                  pageBuilder: (_, __, ___) => const PassengerMain(),
                                  transitionsBuilder: (_, anim, __, child) =>
                                      FadeTransition(opacity: anim, child: child),
                                ),
                                (r) => false,
                              );
                            },
                            style: TextButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50),
                              ),
                            ),
                            child: Text(
                              'Back to Home',
                              style: GoogleFonts.dmSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
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
    );
  }
}

class _RouteRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const _RouteRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) => Row(
    children: [
      HugeIcon(icon: icon, color: color, size: 20),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w500),
            ),
            Text(
              value,
              style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.textPrimary, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    ],
  );
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(50),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        HugeIcon(icon: icon, color: color, size: 13),
        const SizedBox(width: 5),
        Text(
          label,
          style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600, color: color),
        ),
      ],
    ),
  );
}

class _CheckPainter extends CustomPainter {
  final double progress;
  _CheckPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0) return;
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final cx = size.width / 2;
    final cy = size.height / 2;

    final path = Path()
      ..moveTo(cx - 20, cy)
      ..lineTo(cx - 5, cy + 15)
      ..lineTo(cx + 22, cy - 18);

    final total = _pathLength(path);
    final drawn = total * progress;

    final metric = path.computeMetrics().first;
    final extracted = metric.extractPath(0, drawn);
    canvas.drawPath(extracted, paint);
  }

  double _pathLength(Path path) {
    double length = 0;
    for (final m in path.computeMetrics()) {
      length += m.length;
    }
    return length;
  }

  @override
  bool shouldRepaint(_CheckPainter old) => old.progress != progress;
}

class _Particle {
  final double x;
  final double y;
  final double size;
  final Color color;
  final double speed;
  final double angle;

  const _Particle({
    required this.x, required this.y, required this.size,
    required this.color, required this.speed, required this.angle,
  });
}

class _ParticlePainter extends CustomPainter {
  final double progress;
  static final _rng = math.Random(42);

  static final _particles = List.generate(24, (i) => _Particle(
    x: _rng.nextDouble(),
    y: _rng.nextDouble() * 0.6,
    size: 3 + _rng.nextDouble() * 5,
    color: [
      AppColors.success.withOpacity(0.5),
      AppColors.primary.withOpacity(0.4),
      AppColors.orange.withOpacity(0.4),
      const Color(0xFFF59E0B).withOpacity(0.4),
    ][i % 4],
    speed: 0.2 + _rng.nextDouble() * 0.6,
    angle: _rng.nextDouble() * math.pi * 2,
  ));

  _ParticlePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in _particles) {
      final t = (progress * p.speed) % 1.0;
      final dy = t * size.height * 0.3;
      final dx = math.sin(t * math.pi * 2 + p.angle) * 20;

      final paint = Paint()
        ..color = p.color.withOpacity((1 - t) * 0.5)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(p.x * size.width + dx, p.y * size.height + dy),
        p.size * (1 - t * 0.5),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.progress != progress;
}
