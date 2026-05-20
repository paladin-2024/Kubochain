import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/common/press_scale.dart';
import 'home_screen.dart';
import 'bookings_screen.dart';
import 'profile_screen.dart';
import '../common/chat_list_screen.dart';

class PassengerMain extends StatefulWidget {
  const PassengerMain({super.key});

  @override
  State<PassengerMain> createState() => _PassengerMainState();
}

class _PassengerMainState extends State<PassengerMain>
    with TickerProviderStateMixin {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomeScreen(),
    BookingsScreen(),
    ChatListScreen(),
    PassengerProfileScreen(),
  ];

  static const List<_NavItem> _navItems = [
    _NavItem(icon: HugeIcons.strokeRoundedHome01,        label: 'Accueil'),
    _NavItem(icon: HugeIcons.strokeRoundedReceiptDollar, label: 'Trajets'),
    _NavItem(icon: HugeIcons.strokeRoundedMessage01,     label: 'Messages'),
    _NavItem(icon: HugeIcons.strokeRoundedUser,          label: 'Profil'),
  ];

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ));
  }

  void _onTap(int index) {
    if (index == _currentIndex) return;
    HapticFeedback.lightImpact();
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: AppColors.backgroundDark,
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: _FloatingNavBar(
        currentIndex: _currentIndex,
        items: _navItems,
        accentColor: AppColors.primary,
        onTap: _onTap,
      ),
    );
  }
}

// ── 2026 Floating Glass Pill Nav Bar ─────────────────────────────────────────
class _FloatingNavBar extends StatelessWidget {
  final int currentIndex;
  final List<_NavItem> items;
  final ValueChanged<int> onTap;
  final Color accentColor;

  const _FloatingNavBar({
    required this.currentIndex,
    required this.items,
    required this.onTap,
    this.accentColor = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Container(
      color: Colors.transparent,
      padding: EdgeInsets.fromLTRB(20, 8, 20, bottom + 16),
      child: Container(
        height: 68,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: accentColor.withValues(alpha: 0.14),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.14),
              blurRadius: 36,
              offset: const Offset(0, 10),
              spreadRadius: -2,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(27),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(27),
              ),
              child: Row(
                children: List.generate(items.length, (i) {
                  final active = i == currentIndex;
                  return _NavItemWidget(
                    item: items[i],
                    active: active,
                    hasUnread: false,
                    accentColor: accentColor,
                    onTap: () => onTap(i),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItemWidget extends StatelessWidget {
  final _NavItem item;
  final bool active;
  final bool hasUnread;
  final Color accentColor;
  final VoidCallback onTap;

  const _NavItemWidget({
    required this.item,
    required this.active,
    required this.hasUnread,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: PressScale(
        scale: 0.88,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: AppColors.springEasing,
          margin: const EdgeInsets.all(6),
          decoration: active
              ? BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      accentColor.withValues(alpha: 0.14),
                      accentColor.withValues(alpha: 0.07),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                )
              : const BoxDecoration(
                  borderRadius: BorderRadius.only(),
                ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  AnimatedScale(
                    scale: active ? 1.12 : 1.0,
                    duration: const Duration(milliseconds: 300),
                    curve: AppColors.springEasing,
                    child: HugeIcon(
                      icon: item.icon,
                      size: 22,
                      color: active ? accentColor : AppColors.textMuted,
                    ),
                  ),
                  if (hasUnread)
                    Positioned(
                      top: -3,
                      right: -4,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 3),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 220),
                style: GoogleFonts.sora(
                  fontSize: 10,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: active ? accentColor : AppColors.textMuted,
                  letterSpacing: active ? 0.2 : 0,
                ),
                child: Text(item.label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}
