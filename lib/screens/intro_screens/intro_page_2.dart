import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';

class IntroPage2 extends StatefulWidget {
  const IntroPage2({super.key});
  @override
  State<IntroPage2> createState() => _IntroPage2State();
}

class _IntroPage2State extends State<IntroPage2>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _imgFade;
  late Animation<Offset> _textSlide;
  late Animation<double> _textFade;
  late Animation<double> _pillFade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _imgFade   = CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.5, curve: Curves.easeOut));
    _pillFade  = CurvedAnimation(parent: _ctrl, curve: const Interval(0.3, 0.6, curve: Curves.easeOut));
    _textFade  = CurvedAnimation(parent: _ctrl, curve: const Interval(0.45, 1.0, curve: Curves.easeOut));
    _textSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: const Interval(0.45, 1.0, curve: Curves.easeOutCubic)));
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Container(
      color: const Color(0xFFF5F8FF),
      child: Column(
        children: [
          // ── Illustration area — warm orange tint ────────────
          FadeTransition(
            opacity: _imgFade,
            child: Container(
              height: size.height * 0.52,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFFFF7ED), Color(0xFFFEF3C7), Color(0xFFF5F8FF)],
                  stops: [0.0, 0.6, 1.0],
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    top: size.height * 0.03,
                    left: -50,
                    child: _Ring(size: 180, color: const Color(0xFFF97316).withOpacity(0.08)),
                  ),
                  Positioned(
                    bottom: 20,
                    right: -20,
                    child: _Ring(size: 100, color: const Color(0xFFF97316).withOpacity(0.1)),
                  ),
                  // Floating accent dot
                  Positioned(
                    top: 50,
                    right: 40,
                    child: Container(
                      width: 14, height: 14,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF97316).withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: Image.asset(
                      'assets/onboarding2.png',
                      height: size.height * 0.42,
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Text content ─────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 8, 28, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FadeTransition(
                    opacity: _pillFade,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF97316).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Text(
                        'ONE TAP AWAY',
                        style: GoogleFonts.sora(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFEA580C),
                          letterSpacing: 1.4,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  SlideTransition(
                    position: _textSlide,
                    child: FadeTransition(
                      opacity: _textFade,
                      child: RichText(
                        text: TextSpan(
                          style: GoogleFonts.sora(
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0D1629),
                            height: 1.15,
                            letterSpacing: -0.5,
                          ),
                          children: const [
                            TextSpan(text: 'The perfect\nride, '),
                            TextSpan(
                              text: 'instantly.',
                              style: TextStyle(color: Color(0xFFF97316)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  FadeTransition(
                    opacity: _textFade,
                    child: Text(
                      'Book a ride in seconds. Your driver arrives, you go. Zero hassle, maximum comfort.',
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        color: const Color(0xFF64748B),
                        height: 1.6,
                      ),
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

class _Ring extends StatelessWidget {
  final double size;
  final Color color;
  const _Ring({required this.size, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    width: size, height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(color: color, width: 2),
    ),
  );
}
