import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../core/constants/app_colors.dart';
import '../core/services/storage_service.dart';
import 'intro_screens/intro_page_1.dart';
import 'intro_screens/intro_page_2.dart';
import 'intro_screens/intro_page_3.dart';
import 'onboarding.dart';

class OnBoardingScreen extends StatefulWidget {
  const OnBoardingScreen({super.key});

  @override
  State<OnBoardingScreen> createState() => _OnBoardingScreenState();
}

class _OnBoardingScreenState extends State<OnBoardingScreen> {
  final PageController _controller = PageController();
  bool _onLastPage = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goToLanding() async {
    await StorageService.setOnboarded();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const OnBoardingPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          PageView(
            controller: _controller,
            onPageChanged: (index) {
              setState(() => _onLastPage = index == 2);
            },
            children: const [
              IntroPage1(),
              IntroPage2(),
              IntroPage3(),
            ],
          ),

          // Skip button
          Positioned(
            top: 60,
            right: 24,
            child: SafeArea(
              child: GestureDetector(
                onTap: _goToLanding,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundLight,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: const Text(
                    'Skip',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Bottom controls
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SmoothPageIndicator(
                  controller: _controller,
                  count: 3,
                  effect: CustomizableEffect(
                    activeDotDecoration: DotDecoration(
                      width: 24,
                      height: 4,
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    dotDecoration: DotDecoration(
                      width: 24,
                      height: 4,
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                      verticalOffset: 0,
                    ),
                    spacing: 8.0,
                  ),
                ),
                const SizedBox(height: 24),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _onLastPage
                          ? _goToLanding
                          : () => _controller.nextPage(
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.easeInOut,
                              ),
                      child: Text(
                        _onLastPage ? 'Get Started' : 'Next',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
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
