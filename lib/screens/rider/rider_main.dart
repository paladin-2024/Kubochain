import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/notification_service.dart';
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
  int _unreadCount = 0;

  final List<Widget> _pages = const [
    RiderHomeScreen(),
    EarningsScreen(),
    ChatListScreen(),
    NotificationsScreen(),
    RiderProfileScreen(),
  ];

  static const List<_NavItem> _navItems = [
    _NavItem(icon: HugeIcons.strokeRoundedMaps,           label: 'Accueil'),
    _NavItem(icon: HugeIcons.strokeRoundedMoney01,        label: 'Revenus'),
    _NavItem(icon: HugeIcons.strokeRoundedMessage01,      label: 'Messages'),
    _NavItem(icon: HugeIcons.strokeRoundedNotification01, label: 'Alertes'),
    _NavItem(icon: HugeIcons.strokeRoundedUser,           label: 'Profil'),
  ];

  static const int _notifIndex = 3;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ));
    _unreadCount = NotificationService.unreadCount;
    NotificationService.addListener(_onNotifChanged);
  }

  void _onNotifChanged() {
    if (mounted) setState(() => _unreadCount = NotificationService.unreadCount);
  }

  @override
  void dispose() {
    NotificationService.removeListener(_onNotifChanged);
    super.dispose();
  }

  void _onTap(int index) {
    if (index == _currentIndex) return;
    HapticFeedback.lightImpact();
    setState(() => _currentIndex = index);
    if (index == _notifIndex) NotificationService.markAllRead();
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
        accentColor: AppColors.success,
        onTap: _onTap,
        unreadIndex: _notifIndex,
        unreadCount: _unreadCount,
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
                  margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: active
                      ? BoxDecoration(
                          color: accentColor.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(16),
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
                            child: HugeIcon(
                              icon: items[i].icon,
                              key: ValueKey(active),
                              size: active ? 28 : 24,
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
                          fontSize: 9,
                          fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                          color: active ? accentColor : AppColors.textMuted,
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
  final String label;
  const _NavItem({required this.icon, required this.label});
}
