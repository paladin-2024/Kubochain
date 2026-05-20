import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';

class IntroPage3 extends StatefulWidget {
  const IntroPage3({super.key});
  @override
  State<IntroPage3> createState() => _IntroPage3State();
}

class _IntroPage3State extends State<IntroPage3>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _imgFade;
  late Animation<Offset> _textSlide;
  late Animation<double> _textFade;
  late Animation<double> _pillFade;
  late Animation<double> _chipsFade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 950));
    _imgFade   = CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.5, curve: Curves.easeOut));
    _pillFade  = CurvedAnimation(parent: _ctrl, curve: const Interval(0.3, 0.6, curve: Curves.easeOut));
    _textFade  = CurvedAnimation(parent: _ctrl, curve: const Interval(0.4, 0.85, curve: Curves.easeOut));
    _textSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: const Interval(0.4, 0.85, curve: Curves.easeOutCubic)));
    _chipsFade = CurvedAnimation(parent: _ctrl, curve: const Interval(0.65, 1.0, curve: Curves.easeOut));
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
          // ── Illustration — emerald green tint ───────────────
          FadeTransition(
            opacity: _imgFade,
            child: Container(
              height: size.height * 0.52,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFD1FAE5), Color(0xFFECFDF5), Color(0xFFF5F8FF)],
                  stops: [0.0, 0.6, 1.0],
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    top: size.height * 0.02,
                    right: -30,
                    child: _Ring(size: 150, color: AppColors.success.withOpacity(0.1)),
                  ),
                  Positioned(
                    bottom: 30,
                    left: -20,
                    child: _Ring(size: 90, color: AppColors.success.withOpacity(0.12)),
                  ),
                  Positioned(
                    top: 60,
                    left: 32,
                    child: Container(
                      width: 10, height: 10,
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: Image.asset(
                      'assets/onboarding3.png',
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
                        color: AppColors.success.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Text(
                        'SÛR & FIABLE',
                        style: GoogleFonts.sora(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.success,
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
                          children: [
                            const TextSpan(text: 'Roulez en toute\n'),
                            TextSpan(
                              text: 'confiance.',
                              style: TextStyle(color: AppColors.success),
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
                      'Conducteurs vérifiés, suivi en temps réel et tarifs transparents — chaque trajet, à chaque fois.',
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        color: const Color(0xFF64748B),
                        height: 1.6,
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Trust chips
                  FadeTransition(
                    opacity: _chipsFade,
                    child: Row(
                      children: [
                        _TrustChip(icon: HugeIcons.strokeRoundedUserCheck01, label: 'Vérifié', color: AppColors.primary),
                        const SizedBox(width: 10),
                        _TrustChip(icon: HugeIcons.strokeRoundedShield01, label: 'Sécurisé', color: AppColors.success),
                        const SizedBox(width: 10),
                        _TrustChip(icon: HugeIcons.strokeRoundedFlash, label: 'Rapide', color: const Color(0xFFF97316)),
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

class _TrustChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _TrustChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(50),
      border: Border.all(color: color.withOpacity(0.2)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        HugeIcon(icon: icon, color: color, size: 14),
        const SizedBox(width: 5),
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    ),
  );
}
