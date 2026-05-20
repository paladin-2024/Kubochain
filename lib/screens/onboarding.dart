import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/app_colors.dart';
import 'Auth/login.dart';
import 'Auth/signup.dart';

class OnBoardingPage extends StatefulWidget {
  const OnBoardingPage({super.key});

  @override
  State<OnBoardingPage> createState() => _OnBoardingPageState();
}

class _OnBoardingPageState extends State<OnBoardingPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _imageFade;
  late Animation<double> _overlayFade;
  late Animation<Offset> _contentSlide;
  late Animation<double> _contentFade;
  late Animation<double> _ctaFade;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
    _imageFade = CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.4, curve: Curves.easeOut));
    _overlayFade = CurvedAnimation(parent: _ctrl, curve: const Interval(0.2, 0.6, curve: Curves.easeOut));
    _contentSlide = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.35, 0.8, curve: Curves.easeOutCubic)),
    );
    _contentFade = CurvedAnimation(parent: _ctrl, curve: const Interval(0.35, 0.75, curve: Curves.easeOut));
    _ctaFade = CurvedAnimation(parent: _ctrl, curve: const Interval(0.6, 1.0, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Hero image — full bleed
          FadeTransition(
            opacity: _imageFade,
            child: SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: Image.asset(
                'assets/bg-1.png',
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Gradient overlay — dark bottom for text legibility
          FadeTransition(
            opacity: _overlayFade,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Color(0x40000000),
                    Color(0xCC000000),
                    Color(0xF2060C1A),
                  ],
                  stops: [0.0, 0.35, 0.65, 1.0],
                ),
              ),
            ),
          ),

          // Content
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SlideTransition(
              position: _contentSlide,
              child: FadeTransition(
                opacity: _contentFade,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(28, 0, 28, MediaQuery.of(context).padding.bottom + 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Trust badges
                      FadeTransition(
                        opacity: _ctaFade,
                        child: Row(
                          children: [
                            _TrustBadge(icon: HugeIcons.strokeRoundedShield01, label: 'Pilotes vérifiés'),
                            const SizedBox(width: 8),
                            _TrustBadge(icon: HugeIcons.strokeRoundedFlash, label: 'Réservation rapide'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Headline
                      RichText(
                        text: TextSpan(
                          style: GoogleFonts.sora(
                            fontSize: 42,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.1,
                            letterSpacing: -1.0,
                          ),
                          children: const [
                            TextSpan(text: 'En route\nvers '),
                            TextSpan(text: "l'aventure."),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "La réservation boda la plus rapide de Goma.\nInscrivez-vous ou connectez-vous pour commencer.",
                        style: GoogleFonts.dmSans(
                          fontSize: 15,
                          color: Colors.white.withOpacity(0.7),
                          height: 1.55,
                        ),
                      ),

                      const SizedBox(height: 32),

                      // CTA buttons
                      FadeTransition(
                        opacity: _ctaFade,
                        child: Column(
                          children: [
                            // Create Account — primary CTA
                            _LandingButton(
                              label: 'Créer un compte',
                              icon: HugeIcons.strokeRoundedUserAdd01,
                              isPrimary: true,
                              onTap: () {
                                HapticFeedback.mediumImpact();
                                Navigator.push(
                                  context,
                                  PageRouteBuilder(
                                    transitionDuration: const Duration(milliseconds: 350),
                                    pageBuilder: (_, __, ___) => const SignUpPage(),
                                    transitionsBuilder: (_, anim, __, child) =>
                                        SlideTransition(
                                      position: Tween<Offset>(
                                        begin: const Offset(0, 1),
                                        end: Offset.zero,
                                      ).animate(CurvedAnimation(
                                        parent: anim,
                                        curve: Curves.easeOutCubic,
                                      )),
                                      child: child,
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 12),

                            // Log In — secondary
                            _LandingButton(
                              label: 'Se connecter',
                              icon: HugeIcons.strokeRoundedLogin01,
                              isPrimary: false,
                              onTap: () {
                                HapticFeedback.selectionClick();
                                Navigator.push(
                                  context,
                                  PageRouteBuilder(
                                    transitionDuration: const Duration(milliseconds: 350),
                                    pageBuilder: (_, __, ___) => const LoginPage(),
                                    transitionsBuilder: (_, anim, __, child) =>
                                        SlideTransition(
                                      position: Tween<Offset>(
                                        begin: const Offset(0, 1),
                                        end: Offset.zero,
                                      ).animate(CurvedAnimation(
                                        parent: anim,
                                        curve: Curves.easeOutCubic,
                                      )),
                                      child: child,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrustBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _TrustBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(50),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: Colors.white.withOpacity(0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            HugeIcon(icon: icon, color: Colors.white, size: 13),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _LandingButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isPrimary;
  final VoidCallback onTap;

  const _LandingButton({
    required this.label,
    required this.icon,
    required this.isPrimary,
    required this.onTap,
  });

  @override
  State<_LandingButton> createState() => _LandingButtonState();
}

class _LandingButtonState extends State<_LandingButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _press;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _press, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: GestureDetector(
        onTapDown: (_) => _press.forward(),
        onTapUp: (_) { _press.reverse(); widget.onTap(); },
        onTapCancel: () => _press.reverse(),
        child: widget.isPrimary
            ? Container(
                width: double.infinity,
                height: 58,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(50),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.5),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    HugeIcon(icon: widget.icon, color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      widget.label,
                      style: GoogleFonts.sora(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(50),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    width: double.infinity,
                    height: 58,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        HugeIcon(icon: widget.icon, color: Colors.white, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          widget.label,
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
              ),
      ),
    );
  }
}
