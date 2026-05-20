import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../models/ride_model.dart';
import '../../providers/providers.dart';
import '../../widgets/effects/ambient_orbs.dart';
import '../../widgets/common/press_scale.dart';

class EarningsScreen extends ConsumerStatefulWidget {
  const EarningsScreen({super.key});

  @override
  ConsumerState<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends ConsumerState<EarningsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryCtrl;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(driverProvider).loadEarnings();
    });
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  Animation<double> _fade(double start, double end) => CurvedAnimation(
    parent: _entryCtrl,
    curve: Interval(start, end, curve: Curves.easeOut),
  );

  Animation<Offset> _slide(double start, double end) =>
    Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(
      CurvedAnimation(parent: _entryCtrl, curve: Interval(start, end, curve: AppColors.springEasing)),
    );

  @override
  Widget build(BuildContext context) {
    final driver = ref.watch(driverProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Aurora Hero Header ─────────────────────────────────────────────
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fade(0.0, 0.5),
              child: _buildHeroHeader(driver),
            ),
          ),

          // ── Section header ─────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: SlideTransition(
              position: _slide(0.3, 0.7),
              child: FadeTransition(
                opacity: _fade(0.3, 0.7),
                child: _buildSectionHeader(driver),
              ),
            ),
          ),

          // ── Trip list ──────────────────────────────────────────────────────
          if (driver.isLoading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(
                  color: AppColors.success,
                  strokeWidth: 2.5,
                ),
              ),
            )
          else if (driver.completedRides.isEmpty)
            SliverFillRemaining(child: _buildEmpty())
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => SlideTransition(
                    position: _slide(0.4 + i * 0.04, 0.9 + i * 0.02),
                    child: FadeTransition(
                      opacity: _fade(0.4 + i * 0.04, 0.9 + i * 0.02),
                      child: _TripCard(ride: driver.completedRides[i], index: i),
                    ),
                  ),
                  childCount: driver.completedRides.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeroHeader(dynamic driver) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF059669), Color(0xFF10B981), Color(0xFF34D399)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Orbs behind content
          Positioned.fill(
            child: AmbientOrbs(
              color: Colors.white,
              orbCount: 3,
              maxOpacity: 0.07,
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title row
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25),
                            width: 1,
                          ),
                        ),
                        child: const HugeIcon(
                          icon: HugeIcons.strokeRoundedWallet01,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mes revenus',
                            style: GoogleFonts.sora(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            'Tableau de bord financier',
                            style: GoogleFonts.sora(
                              color: Colors.white.withValues(alpha: 0.75),
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Stat cards row
                  Row(
                    children: [
                      Expanded(
                        child: _GlassStatCard(
                          label: "Aujourd'hui",
                          value: 'FC ${driver.todayEarnings.toStringAsFixed(0)}',
                          icon: HugeIcons.strokeRoundedSun01,
                          valueFontSize: driver.todayEarnings >= 10000 ? 15 : 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _GlassStatCard(
                          label: 'Total gagné',
                          value: 'FC ${driver.totalEarnings.toStringAsFixed(0)}',
                          icon: HugeIcons.strokeRoundedSavings,
                          valueFontSize: driver.totalEarnings >= 100000 ? 13 : 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _GlassStatCard(
                          label: 'Courses',
                          value: '${driver.completedRides.length}',
                          icon: HugeIcons.strokeRoundedMotorbike01,
                          valueFontSize: 22,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(dynamic driver) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const HugeIcon(
              icon: HugeIcons.strokeRoundedClock01,
              color: AppColors.success,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Historique des courses',
            style: GoogleFonts.sora(
              color: AppColors.textOnDark,
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const Spacer(),
          if (driver.completedRides.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Text(
                '${driver.completedRides.length} courses',
                style: GoogleFonts.sora(
                  color: AppColors.success,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              gradient: AppColors.riderGradient,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.success.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const HugeIcon(
              icon: HugeIcons.strokeRoundedReceiptDollar,
              size: 36,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Aucune course pour l\'instant',
            style: GoogleFonts.sora(
              color: AppColors.textOnDark,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Vos courses terminées apparaîtront ici',
            style: GoogleFonts.sora(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Glass Stat Card (for hero) ────────────────────────────────────────────────
class _GlassStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final double valueFontSize;

  const _GlassStatCard({
    required this.label,
    required this.value,
    required this.icon,
    this.valueFontSize = 18,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.28),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: HugeIcon(icon: icon, color: Colors.white, size: 20),
              ),
              const SizedBox(height: 10),
              Text(
                value,
                style: GoogleFonts.sora(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: valueFontSize,
                  letterSpacing: -0.3,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: GoogleFonts.sora(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Trip Card ─────────────────────────────────────────────────────────────────
class _TripCard extends StatelessWidget {
  final RideModel ride;
  final int index;

  const _TripCard({required this.ride, required this.index});

  @override
  Widget build(BuildContext context) {
    return PressScale(
      scale: 0.97,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.success.withValues(alpha: 0.10),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.success.withValues(alpha: 0.07),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                gradient: AppColors.riderGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.success.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const HugeIcon(
                icon: HugeIcons.strokeRoundedCheckmarkCircle01,
                color: Colors.white,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ride.destination.address.split(',').first,
                    style: GoogleFonts.sora(
                      color: AppColors.textOnDark,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const HugeIcon(
                        icon: HugeIcons.strokeRoundedClock01,
                        size: 12,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('MMM dd • hh:mm a').format(ride.createdAt),
                        style: GoogleFonts.sora(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                gradient: AppColors.riderGradient,
                borderRadius: BorderRadius.circular(50),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.success.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                'FC ${ride.price.toStringAsFixed(0)}',
                style: GoogleFonts.sora(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
