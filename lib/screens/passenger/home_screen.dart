import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/notification_service.dart';
import '../../providers/providers.dart';
import '../../providers/location_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/ride_model.dart';
import '../../widgets/effects/ambient_orbs.dart';
import '../../widgets/common/press_scale.dart';
import '../common/notifications_screen.dart';
import 'book_ride_screen.dart';
import 'top_riders_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  int _unreadCount = 0;
  late AnimationController _entryCtrl;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(locationProvider).init();
      ref.read(rideProvider).fetchRideHistory();
    });
    NotificationService.addListener(_onNotificationsChanged);
    _unreadCount = NotificationService.unreadCount;
  }

  void _onNotificationsChanged() {
    if (mounted) setState(() => _unreadCount = NotificationService.unreadCount);
  }

  @override
  void dispose() {
    NotificationService.removeListener(_onNotificationsChanged);
    _entryCtrl.dispose();
    super.dispose();
  }

  Animation<double> _fade(double start, double end) => CurvedAnimation(
    parent: _entryCtrl,
    curve: Interval(start, end, curve: Curves.easeOut),
  );

  Animation<Offset> _slide(double start, double end) =>
    Tween<Offset>(begin: const Offset(0, 0.18), end: Offset.zero).animate(
      CurvedAnimation(parent: _entryCtrl, curve: Interval(start, end, curve: AppColors.springEasing)),
    );

  @override
  Widget build(BuildContext context) {
    final auth     = ref.watch(authProvider);
    final loc      = ref.watch(locationProvider);
    final ride     = ref.watch(rideProvider);
    final center   = loc.currentLocation ?? AppConstants.defaultLocation;
    final hour     = DateTime.now().hour;
    final greeting = hour < 12 ? 'Bonjour' : hour < 17 ? 'Bon après-midi' : 'Bonsoir';

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Hero Header ──────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fade(0.0, 0.5),
              child: _buildHeader(auth, greeting),
            ),
          ),

          // ── Search bar ───────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: SlideTransition(
              position: _slide(0.1, 0.55),
              child: FadeTransition(
                opacity: _fade(0.1, 0.55),
                child: _buildSearchBar(),
              ),
            ),
          ),

          // ── Quick actions ────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: SlideTransition(
              position: _slide(0.2, 0.65),
              child: FadeTransition(
                opacity: _fade(0.2, 0.65),
                child: _buildQuickActions(),
              ),
            ),
          ),

          // ── Safety card ──────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: SlideTransition(
              position: _slide(0.3, 0.75),
              child: FadeTransition(
                opacity: _fade(0.3, 0.75),
                child: _buildSafetyCard(),
              ),
            ),
          ),

          // ── Map ──────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: SlideTransition(
              position: _slide(0.4, 0.85),
              child: FadeTransition(
                opacity: _fade(0.4, 0.85),
                child: _buildMapSection(center, loc),
              ),
            ),
          ),

          // ── Promo banner ─────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: SlideTransition(
              position: _slide(0.5, 0.9),
              child: FadeTransition(
                opacity: _fade(0.5, 0.9),
                child: _buildPromoBanner(),
              ),
            ),
          ),

          // ── Recent rides ─────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: SlideTransition(
              position: _slide(0.55, 0.95),
              child: FadeTransition(
                opacity: _fade(0.55, 0.95),
                child: const Padding(
                  padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
                  child: _SectionHeader(title: 'Trajets récents', actionLabel: 'Voir tout'),
                ),
              ),
            ),
          ),

          if (ride.rideHistory.isEmpty)
            const SliverToBoxAdapter(child: _EmptyRides())
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => SlideTransition(
                  position: _slide(0.6 + i * 0.04, 1.0),
                  child: FadeTransition(
                    opacity: _fade(0.6 + i * 0.04, 1.0),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                      child: _RideHistoryCard(ride: ride.rideHistory[i]),
                    ),
                  ),
                ),
                childCount: ride.rideHistory.take(4).length,
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 110)),
        ],
      ),
    );
  }

  Widget _buildHeader(AuthProvider auth, String greeting) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFEFF6FF), Color(0xFFEDE9FE), Color(0xFFF0F7FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Ambient orbs background
          Positioned.fill(
            child: AmbientOrbs(
              color: AppColors.primary,
              orbCount: 3,
              maxOpacity: 0.06,
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppColors.primary.withValues(alpha: 0.18),
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6, height: 6,
                                    decoration: const BoxDecoration(
                                      color: AppColors.success,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    greeting,
                                    style: GoogleFonts.sora(
                                      fontSize: 11,
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        RichText(
                          text: TextSpan(
                            style: GoogleFonts.sora(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textOnDark,
                              letterSpacing: -0.5,
                              height: 1.1,
                            ),
                            children: [
                              const TextSpan(text: 'Salut, '),
                              TextSpan(
                                text: auth.user?.firstName ?? 'là',
                                style: const TextStyle(color: AppColors.primary),
                              ),
                              const TextSpan(text: ' 👋'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Où voulez-vous aller aujourd\'hui ?',
                          style: GoogleFonts.sora(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Notification bell
                  PressScale(
                    scale: 0.90,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                    ),
                    child: Stack(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.15),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.12),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: HugeIcon(
                              icon: HugeIcons.strokeRoundedNotification01,
                              size: 22,
                              color: AppColors.textOnDark,
                            ),
                          ),
                        ),
                        if (_unreadCount > 0)
                          Positioned(
                            top: 4, right: 4,
                            child: Container(
                              width: 16, height: 16,
                              decoration: const BoxDecoration(
                                color: AppColors.error,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  _unreadCount > 9 ? '9+' : '$_unreadCount',
                                  style: const TextStyle(
                                    color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ),
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

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      child: PressScale(
        scale: 0.98,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BookRideScreen()),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.12),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.10),
                blurRadius: 24,
                offset: const Offset(0, 6),
                spreadRadius: -2,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: AppColors.auroraGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.30),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const HugeIcon(
                  icon: HugeIcons.strokeRoundedSearch01,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Où allez-vous ?',
                      style: GoogleFonts.sora(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textOnDark,
                      ),
                    ),
                    Text(
                      'Réservez votre boda en toute sécurité',
                      style: GoogleFonts.sora(
                        fontSize: 11,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  'Trajet',
                  style: GoogleFonts.sora(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      _QuickAction(icon: HugeIcons.strokeRoundedHome01,      label: 'Maison',      color: AppColors.primary,    dest: BookRideScreen()),
      _QuickAction(icon: HugeIcons.strokeRoundedBriefcase01, label: 'Travail',     color: AppColors.safetyGold, dest: BookRideScreen()),
      _QuickAction(icon: HugeIcons.strokeRoundedFavourite,   label: 'Favoris',     color: AppColors.error,      dest: BookRideScreen()),
      _QuickAction(icon: HugeIcons.strokeRoundedMedal01,     label: 'Top Pilotes', color: AppColors.gold,       dest: TopRidersScreen()),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: actions.map((a) => Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: PressScale(
              scale: 0.91,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => a.dest),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: a.color.withValues(alpha: 0.12),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: a.color.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: a.color.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: HugeIcon(icon: a.icon, size: 18, color: a.color),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      a.label,
                      style: GoogleFonts.sora(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textOnDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildSafetyCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: PressScale(
        scale: 0.98,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.safetyGold.withValues(alpha: 0.10),
                AppColors.orange.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.safetyGold.withValues(alpha: 0.22),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.safetyGold.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: AppColors.safetyGradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.safetyGold.withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const HugeIcon(icon: HugeIcons.strokeRoundedShieldUser, size: 22, color: Colors.white),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Roulez en sécurité avec KuboChain',
                      style: GoogleFonts.sora(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.safetyGold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Conducteurs vérifiés • SOS disponible',
                      style: GoogleFonts.sora(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              HugeIcon(
                icon: HugeIcons.strokeRoundedArrowRight01,
                color: AppColors.safetyGold.withValues(alpha: 0.6),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapSection(LatLng center, LocationProvider loc) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8, height: 8,
                decoration: BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.success.withValues(alpha: 0.5),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Votre position',
                style: GoogleFonts.sora(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textOnDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 190,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.12),
              ),
              boxShadow: AppColors.cardShadow,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(initialCenter: center, initialZoom: 14.5),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
                        subdomains: const ['a', 'b', 'c', 'd'],
                        userAgentPackageName: 'com.kubochain.app',
                      ),
                      if (loc.currentLocation != null)
                        MarkerLayer(markers: [
                          Marker(
                            point: loc.currentLocation!,
                            width: 44, height: 44,
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.primary,
                                border: Border.all(color: Colors.white, width: 2.5),
                                boxShadow: AppColors.primaryGlow,
                              ),
                              child: const HugeIcon(
                                icon: HugeIcons.strokeRoundedLocation01,
                                color: Colors.white, size: 20,
                              ),
                            ),
                          ),
                        ]),
                    ],
                  ),
                  Positioned(
                    top: 0, left: 0, right: 0,
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.black.withValues(alpha: 0.2), Colors.transparent],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
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
    );
  }

  Widget _buildPromoBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: PressScale(
        scale: 0.97,
        onTap: () => _showPromoSheet(context),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withValues(alpha: 0.12),
                AppColors.indigo.withValues(alpha: 0.08),
                AppColors.primaryUltraLight,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.18),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.10),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: AppColors.auroraGradient,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'OFFRE LIMITÉE',
                        style: GoogleFonts.sora(
                          fontSize: 9,
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '20% de réduction\nsur vos 3 prochains trajets',
                      style: GoogleFonts.sora(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textOnDark,
                        height: 1.25,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Appuyez pour entrer votre code',
                      style: GoogleFonts.sora(
                        fontSize: 11,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  gradient: AppColors.auroraGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const HugeIcon(
                  icon: HugeIcons.strokeRoundedDiscountTag01,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPromoSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _PromoSheet(),
    );
  }
}

// ── Section header ─────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  const _SectionHeader({required this.title, this.actionLabel});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.sora(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.textOnDark,
            letterSpacing: -0.3,
          ),
        ),
        if (actionLabel != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              actionLabel!,
              style: GoogleFonts.sora(
                fontSize: 11,
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}

// ── Empty rides ────────────────────────────────────────────────────────────────
class _EmptyRides extends StatelessWidget {
  const _EmptyRides();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.borderDark),
          boxShadow: AppColors.softShadow,
        ),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const HugeIcon(
                icon: HugeIcons.strokeRoundedBicycle01,
                size: 32,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun trajet',
              style: GoogleFonts.sora(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textOnDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Votre premier trajet boda vous attend !',
              style: GoogleFonts.sora(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Ride history card ──────────────────────────────────────────────────────────
class _RideHistoryCard extends StatelessWidget {
  final RideModel ride;
  const _RideHistoryCard({required this.ride});

  Color _statusColor() {
    switch (ride.status) {
      case 'completed': return AppColors.success;
      case 'cancelled': return AppColors.error;
      case 'in_progress': return AppColors.primary;
      default: return AppColors.warning;
    }
  }

  String _statusLabel() {
    switch (ride.status) {
      case 'completed': return 'Terminé';
      case 'cancelled': return 'Annulé';
      case 'in_progress': return 'En cours';
      default: return 'En attente';
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor();

    return PressScale(
      scale: 0.97,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: AppColors.borderDark,
            width: 0.8,
          ),
          boxShadow: AppColors.cardShadow,
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              child: Row(
                children: [
                  Column(
                    children: [
                      Container(
                        width: 10, height: 10,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          boxShadow: AppColors.primaryGlow,
                        ),
                      ),
                      Container(
                        width: 1.5, height: 28,
                        color: AppColors.borderDark,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                      ),
                      Container(
                        width: 10, height: 10,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ride.pickup.address.split(',').first,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.sora(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textOnDark,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          ride.destination.address.split(',').first,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.sora(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textOnDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: AppColors.divider),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.25),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      _statusLabel(),
                      style: GoogleFonts.sora(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${ride.createdAt.day} ${_month(ride.createdAt.month)}, ${ride.createdAt.hour}:${ride.createdAt.minute.toString().padLeft(2, '0')}',
                    style: GoogleFonts.sora(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'FC ${ride.price.toStringAsFixed(0)}',
                    style: GoogleFonts.sora(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textOnDark,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _month(int m) => const [
    '', 'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun',
    'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'
  ][m];
}

class _QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final Widget dest;
  const _QuickAction({required this.icon, required this.label, required this.color, required this.dest});
}

// ── Promo Code Sheet ───────────────────────────────────────────────────────────
class _PromoSheet extends StatefulWidget {
  const _PromoSheet();

  @override
  State<_PromoSheet> createState() => _PromoSheetState();
}

class _PromoSheetState extends State<_PromoSheet> {
  final _ctrl = TextEditingController();
  String? _status;
  static const _validCodes = {'KRIDE20', 'BIENVENUE', 'GOMA10'};

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  void _apply() {
    final code = _ctrl.text.trim().toUpperCase();
    setState(() => _status = _validCodes.contains(code) ? 'success' : 'error');
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Entrez votre code promo',
            style: GoogleFonts.sora(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textOnDark),
          ),
          const SizedBox(height: 6),
          Text(
            'Codes disponibles : KRIDE20 · BIENVENUE · GOMA10',
            style: GoogleFonts.sora(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.backgroundDark,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _status == 'error'
                          ? AppColors.error
                          : _status == 'success'
                              ? AppColors.success
                              : AppColors.borderDark,
                    ),
                  ),
                  child: TextField(
                    controller: _ctrl,
                    textCapitalization: TextCapitalization.characters,
                    style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 2),
                    decoration: InputDecoration(
                      hintText: 'CODE PROMO',
                      hintStyle: GoogleFonts.sora(fontSize: 13, color: AppColors.textSecondary, letterSpacing: 1),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    onChanged: (_) => setState(() => _status = null),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              PressScale(
                onTap: _apply,
                child: Container(
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: AppColors.primaryGlow,
                  ),
                  child: Center(
                    child: Text(
                      'Appliquer',
                      style: GoogleFonts.sora(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_status != null) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                HugeIcon(
                  icon: _status == 'success'
                      ? HugeIcons.strokeRoundedCheckmarkCircle01
                      : HugeIcons.strokeRoundedAlertCircle,
                  color: _status == 'success' ? AppColors.success : AppColors.error,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _status == 'success'
                        ? '🎉 Code appliqué ! 20% de réduction sur votre prochain trajet.'
                        : 'Code invalide. Vérifiez et réessayez.',
                    style: GoogleFonts.sora(
                      fontSize: 13,
                      color: _status == 'success' ? AppColors.success : AppColors.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (_status == 'success') ...[
            const SizedBox(height: 16),
            PressScale(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    'Réserver maintenant',
                    style: GoogleFonts.sora(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
