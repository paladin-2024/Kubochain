import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import 'rider_home_screen.dart';
import 'earnings_screen.dart';
import 'rider_profile_screen.dart';
import '../common/chat_list_screen.dart';
import '../common/notifications_screen.dart';

class RiderMain extends StatefulWidget {
  const RiderMain({super.key});

  @override
  State<RiderMain> createState() => _RiderMainState();
}

class _RiderMainState extends State<RiderMain> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _indicatorController;

  final List<Widget> _pages = const [
    RiderHomeScreen(),
    EarningsScreen(),
    ChatListScreen(),
    NotificationsScreen(),
    RiderProfileScreen(),
  ];

  final List<_NavItem> _navItems = const [
    _NavItem(icon: Icons.map_rounded,                    outlineIcon: Icons.map_outlined,                      label: 'Home'),
    _NavItem(icon: Icons.account_balance_wallet_rounded, outlineIcon: Icons.account_balance_wallet_outlined,    label: 'Earnings'),
    _NavItem(icon: Icons.chat_bubble_rounded,            outlineIcon: Icons.chat_bubble_outline_rounded,        label: 'Chat'),
    _NavItem(icon: Icons.notifications_rounded,          outlineIcon: Icons.notifications_outlined,             label: 'Alerts'),
    _NavItem(icon: Icons.person_rounded,                 outlineIcon: Icons.person_outline_rounded,             label: 'Profile'),
  ];

  @override
  void initState() {
    super.initState();
    _indicatorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      systemNavigationBarColor: Color(0xFF0D1525),
      systemNavigationBarIconBrightness: Brightness.light,
    ));
  }

  @override
  void dispose() {
    _indicatorController.dispose();
    super.dispose();
  }

  void _onTap(int index) {
    if (index == _currentIndex) return;
    HapticFeedback.lightImpact();
    setState(() => _currentIndex = index);
    _indicatorController.forward(from: 0);
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
        onTap: _onTap,
        accentColor: AppColors.success,
      ),
    );
  }
}

// ── Floating Nav Bar ──────────────────────────────────────────────────────────
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
    return Container(
      height: 80 + MediaQuery.of(context).padding.bottom,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0D1525), Color(0xFF080D18)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border(
          top: BorderSide(color: AppColors.borderDark, width: 0.5),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 8,
          top: 8,
          left: 8,
          right: 8,
        ),
        child: Row(
          children: List.generate(items.length, (i) {
            final active = i == currentIndex;
            return Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onTap(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: active
                      ? BoxDecoration(
                          color: accentColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: accentColor.withOpacity(0.25),
                            width: 0.5,
                          ),
                        )
                      : null,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          active ? items[i].icon : items[i].outlineIcon,
                          key: ValueKey(active),
                          size: 22,
                          color: active
                              ? accentColor
                              : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight:
                              active ? FontWeight.w700 : FontWeight.w400,
                          color: active
                              ? accentColor
                              : AppColors.textSecondary,
                          letterSpacing: active ? 0.3 : 0,
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
  const _NavItem(
      {required this.icon,
      required this.outlineIcon,
      required this.label});
}
