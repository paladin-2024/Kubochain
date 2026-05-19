import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
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
    _NavItem(
      icon: Icons.home_rounded,
      outlineIcon: Icons.home_outlined,
      label: 'Home',
    ),
    _NavItem(
      icon: Icons.receipt_long_rounded,
      outlineIcon: Icons.receipt_long_outlined,
      label: 'Trips',
    ),
    _NavItem(
      icon: Icons.chat_bubble_rounded,
      outlineIcon: Icons.chat_bubble_outline_rounded,
      label: 'Chat',
    ),
    _NavItem(
      icon: Icons.person_rounded,
      outlineIcon: Icons.person_outline_rounded,
      label: 'Profile',
    ),
  ];

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
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
      bottomNavigationBar: _PremiumNavBar(
        currentIndex: _currentIndex,
        items: _navItems,
        accentColor: AppColors.primary,
        onTap: _onTap,
      ),
    );
  }
}

// ── Premium Nav Bar ───────────────────────────────────────────────────────────
class _PremiumNavBar extends StatelessWidget {
  final int currentIndex;
  final List<_NavItem> items;
  final ValueChanged<int> onTap;
  final Color accentColor;
  final int unreadIndex;
  final int unreadCount;

  const _PremiumNavBar({
    required this.currentIndex,
    required this.items,
    required this.onTap,
    this.accentColor = AppColors.primary,
    this.unreadIndex = -1,
    this.unreadCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Container(
      height: 74 + bottom,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: AppColors.navShadow,
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottom, top: 4, left: 4, right: 4),
        child: Row(
          children: List.generate(items.length, (i) {
            final active = i == currentIndex;
            final hasUnread = i == unreadIndex && unreadCount > 0;
            return Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onTap(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: active
                      ? BoxDecoration(
                          color: accentColor.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(18),
                        )
                      : null,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 180),
                            transitionBuilder: (child, anim) => ScaleTransition(
                              scale: anim,
                              child: child,
                            ),
                            child: Icon(
                              active ? items[i].icon : items[i].outlineIcon,
                              key: ValueKey(active),
                              size: active ? 30 : 26,
                              color: active ? accentColor : AppColors.textMuted,
                            ),
                          ),
                          if (hasUnread)
                            Positioned(
                              top: -2,
                              right: -4,
                              child: Container(
                                width: 9,
                                height: 9,
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
                        duration: const Duration(milliseconds: 180),
                        style: GoogleFonts.sora(
                          fontSize: 10,
                          fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                          color: active ? accentColor : AppColors.textMuted,
                          letterSpacing: active ? 0.2 : 0,
                        ),
                        child: Text(items[i].label),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData outlineIcon;
  final String label;
  const _NavItem({required this.icon, required this.outlineIcon, required this.label});
}
