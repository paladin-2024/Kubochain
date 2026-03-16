import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/ride_provider.dart';
import 'passenger_main.dart';
import 'top_riders_screen.dart';

class RateDriverScreen extends StatefulWidget {
  const RateDriverScreen({super.key});

  @override
  State<RateDriverScreen> createState() => _RateDriverScreenState();
}

class _RateDriverScreenState extends State<RateDriverScreen>
    with TickerProviderStateMixin {
  int _rating = 5;
  final _commentCtrl = TextEditingController();
  bool _isLoading = false;
  final Set<String> _selectedTags = {};

  late AnimationController _celebrationCtrl;
  late AnimationController _fadeCtrl;
  late AnimationController _starsCtrl;
  late Animation<double> _fadeAnim;
  late Animation<double> _starsAnim;

  static const _allTags = [
    ('⚡ Fast', 'Fast'),
    ('🛡️ Safe', 'Safe'),
    ('😊 Friendly', 'Friendly'),
    ('🏆 Professional', 'Professional'),
    ('🧹 Clean Bike', 'Clean Bike'),
    ('🗺️ Good Route', 'Good Route'),
    ('🔇 Quiet Ride', 'Quiet Ride'),
    ('⭐ Excellent', 'Excellent'),
  ];

  @override
  void initState() {
    super.initState();

    _celebrationCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..forward();

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();

    _starsCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _starsAnim = CurvedAnimation(parent: _starsCtrl, curve: Curves.elasticOut);
  }

  @override
  void dispose() {
    _celebrationCtrl.dispose();
    _fadeCtrl.dispose();
    _starsCtrl.dispose();
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    final ride = context.read<RideProvider>();
    await ride.rateRide(
      _rating,
      _commentCtrl.text.trim(),
      tags: _selectedTags.toList(),
    );
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const PassengerMain()),
        (r) => false,
      );
    }
  }

  void _skipRating() {
    context.read<RideProvider>().resetRide();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const PassengerMain()),
      (r) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ride = context.watch<RideProvider>();
    final currentRide = ride.currentRide;
    final driver = currentRide?.driver;
    final driverName =
        '${driver?['firstName'] ?? ''} ${driver?['lastName'] ?? ''}'.trim();

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Stack(
        children: [
          // Celebration particles
          AnimatedBuilder(
            animation: _celebrationCtrl,
            builder: (_, __) => CustomPaint(
              painter: _ConfettiPainter(_celebrationCtrl.value),
              size: MediaQuery.of(context).size,
            ),
          ),

          // Subtle glow at top
          Container(
            height: 300,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -1),
                radius: 1.0,
                colors: [
                  AppColors.success.withOpacity(0.12),
                  Colors.transparent,
                ],
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                child: Column(
                  children: [
                    // Success badge
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.successGradient,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.success.withOpacity(0.4),
                            blurRadius: 32,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.check_rounded,
                          color: Colors.white, size: 44),
                    ),
                    const SizedBox(height: 20),

                    Text(
                      'You have arrived!',
                      style: GoogleFonts.sora(
                        color: AppColors.textOnDark,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Hope you had a safe & great ride.',
                      style: GoogleFonts.sora(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Fare summary card
                    if (currentRide != null)
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.success.withOpacity(0.1),
                              AppColors.primary.withOpacity(0.05),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: AppColors.success.withOpacity(0.2)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _TripSummaryItem(
                              icon: Icons.monetization_on_rounded,
                              label: 'Total Fare',
                              value:
                                  'FC ${currentRide.price.toStringAsFixed(0)}',
                              color: AppColors.success,
                            ),
                            Container(
                                width: 1,
                                height: 40,
                                color: AppColors.borderDark),
                            _TripSummaryItem(
                              icon: Icons.route_rounded,
                              label: 'Distance',
                              value:
                                  '${currentRide.distance.toStringAsFixed(1)} km',
                              color: AppColors.primary,
                            ),
                            Container(
                                width: 1,
                                height: 40,
                                color: AppColors.borderDark),
                            _TripSummaryItem(
                              icon: Icons.directions_bike_rounded,
                              label: 'Type',
                              value: currentRide.rideType == 'premium'
                                  ? 'Premium'
                                  : 'Economy',
                              color: AppColors.gold,
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 28),

                    // Driver card
                    if (driver != null) ...[
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppColors.cardDark,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.borderDark),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: AppColors.primaryGradient,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.3),
                                    blurRadius: 16,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  driverName.isNotEmpty
                                      ? driverName[0].toUpperCase()
                                      : 'D',
                                  style: GoogleFonts.sora(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 24,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    driverName.isEmpty ? 'Your Rider' : driverName,
                                    style: GoogleFonts.sora(
                                      color: AppColors.textOnDark,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    driver['vehicle']?['make'] ?? 'Boda Rider',
                                    style: GoogleFonts.sora(
                                      color: AppColors.textSecondary,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Current avg rating
                            Column(
                              children: [
                                const Icon(Icons.star_rounded,
                                    color: AppColors.gold, size: 20),
                                Text(
                                  '${driver['rating'] ?? '5.0'}',
                                  style: GoogleFonts.sora(
                                    color: AppColors.textOnDark,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  'avg',
                                  style: GoogleFonts.sora(
                                    color: AppColors.textSecondary,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                    ],

                    // Star rating
                    Text(
                      'Rate your rider',
                      style: GoogleFonts.sora(
                        color: AppColors.textOnDark,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Your rating helps improve safety for everyone',
                      style: GoogleFonts.sora(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 20),

                    ScaleTransition(
                      scale: _starsAnim,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (i) {
                          final filled = i < _rating;
                          return GestureDetector(
                            onTap: () {
                              setState(() => _rating = i + 1);
                              _starsCtrl.forward(from: 0);
                            },
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 6),
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child: Icon(
                                  filled
                                      ? Icons.star_rounded
                                      : Icons.star_border_rounded,
                                  key: ValueKey('$i$filled'),
                                  size: 48,
                                  color: filled
                                      ? AppColors.gold
                                      : AppColors.textSecondary
                                          .withOpacity(0.4),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),

                    const SizedBox(height: 8),
                    Text(
                      _ratingLabel(_rating),
                      style: GoogleFonts.sora(
                        color: _ratingColor(_rating),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Tag chips
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'What stood out?',
                        style: GoogleFonts.sora(
                          color: AppColors.textOnDark,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _allTags.map((tag) {
                        final selected = _selectedTags.contains(tag.$2);
                        return GestureDetector(
                          onTap: () => setState(() {
                            if (selected) {
                              _selectedTags.remove(tag.$2);
                            } else {
                              _selectedTags.add(tag.$2);
                            }
                          }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.primary.withOpacity(0.15)
                                  : AppColors.cardDark,
                              borderRadius: BorderRadius.circular(50),
                              border: Border.all(
                                color: selected
                                    ? AppColors.primary.withOpacity(0.5)
                                    : AppColors.borderDark,
                                width: selected ? 1.5 : 1,
                              ),
                            ),
                            child: Text(
                              tag.$1,
                              style: GoogleFonts.sora(
                                color: selected
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                                fontSize: 12,
                                fontWeight: selected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 24),

                    // Comment field
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.cardDark,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.borderDark),
                      ),
                      child: TextField(
                        controller: _commentCtrl,
                        maxLines: 3,
                        style: GoogleFonts.sora(
                            color: AppColors.textOnDark, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Share your experience (optional)...',
                          hintStyle: GoogleFonts.sora(
                              color: AppColors.textSecondary.withOpacity(0.6),
                              fontSize: 13),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: AppColors.primaryGlow,
                        ),
                        child: TextButton(
                          onPressed: _isLoading ? null : _submit,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  'Submit Rating',
                                  style: GoogleFonts.sora(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // View leaderboard
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton.icon(
                          onPressed: _skipRating,
                          icon: const Icon(Icons.skip_next_rounded,
                              color: AppColors.textSecondary, size: 16),
                          label: Text(
                            'Skip',
                            style: GoogleFonts.sora(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        TextButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const TopRidersScreen()),
                          ),
                          icon: const Icon(Icons.emoji_events_rounded,
                              color: AppColors.gold, size: 16),
                          label: Text(
                            'Top Riders',
                            style: GoogleFonts.sora(
                              color: AppColors.gold,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _ratingLabel(int r) {
    switch (r) {
      case 1: return 'Poor';
      case 2: return 'Below Average';
      case 3: return 'Average';
      case 4: return 'Good';
      default: return 'Excellent!';
    }
  }

  Color _ratingColor(int r) {
    if (r <= 2) return AppColors.error;
    if (r == 3) return AppColors.warning;
    if (r == 4) return AppColors.primary;
    return AppColors.success;
  }
}

// ── Trip Summary Item ──────────────────────────────────────────────────────────
class _TripSummaryItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _TripSummaryItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.sora(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.sora(
            color: AppColors.textSecondary,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

// ── Confetti Painter ───────────────────────────────────────────────────────────
class _ConfettiPainter extends CustomPainter {
  final double progress;
  _ConfettiPainter(this.progress);

  static final _rng = Random(42);
  static final _particles = List.generate(40, (i) => _ConfettiParticle(
    x: _rng.nextDouble(),
    startY: -0.05 - _rng.nextDouble() * 0.3,
    size: 4.0 + _rng.nextDouble() * 6,
    speed: 0.3 + _rng.nextDouble() * 0.5,
    color: [
      AppColors.primary,
      AppColors.success,
      AppColors.gold,
      AppColors.safetyGold,
      const Color(0xFFFF6B6B),
    ][i % 5],
    rotation: _rng.nextDouble() * 2 * pi,
    rotationSpeed: (_rng.nextDouble() - 0.5) * 8,
    swayAmp: 0.02 + _rng.nextDouble() * 0.04,
    swayFreq: 1.5 + _rng.nextDouble() * 2,
  ));

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in _particles) {
      final y = p.startY + progress * p.speed;
      if (y < 0 || y > 1.1) continue;
      final x = p.x + p.swayAmp * sin(progress * p.swayFreq * 2 * pi);
      final rot = p.rotation + progress * p.rotationSpeed;
      final opacity = (1 - progress * 0.8).clamp(0.0, 1.0);
      final paint = Paint()..color = p.color.withOpacity(opacity);

      canvas.save();
      canvas.translate(x * size.width, y * size.height);
      canvas.rotate(rot);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset.zero, width: p.size, height: p.size * 0.5),
          const Radius.circular(1),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) =>
      old.progress != progress;
}

class _ConfettiParticle {
  final double x, startY, size, speed, swayAmp, swayFreq, rotation, rotationSpeed;
  final Color color;
  const _ConfettiParticle({
    required this.x,
    required this.startY,
    required this.size,
    required this.speed,
    required this.color,
    required this.rotation,
    required this.rotationSpeed,
    required this.swayAmp,
    required this.swayFreq,
  });
}
