import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/api_service.dart';

class TopRidersScreen extends StatefulWidget {
  const TopRidersScreen({super.key});

  @override
  State<TopRidersScreen> createState() => _TopRidersScreenState();
}

class _TopRidersScreenState extends State<TopRidersScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  List<Map<String, dynamic>> _riders = [];
  bool _loading = true;
  String _sortBy = 'rating'; // rating | trips | earnings

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _load();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.getTopRatedDrivers();
      final list = (res.data['riders'] as List? ?? [])
          .cast<Map<String, dynamic>>();
      setState(() {
        _riders = list;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _sorted {
    final copy = List<Map<String, dynamic>>.from(_riders);
    if (_sortBy == 'trips') {
      copy.sort((a, b) =>
          (b['totalRides'] as num).compareTo(a['totalRides'] as num));
    } else if (_sortBy == 'earnings') {
      copy.sort((a, b) =>
          (b['totalEarnings'] as num).compareTo(a['totalEarnings'] as num));
    } else {
      copy.sort((a, b) {
        final r = (b['rating'] as num).compareTo(a['rating'] as num);
        if (r != 0) return r;
        return (b['ratingCount'] as num).compareTo(a['ratingCount'] as num);
      });
    }
    return copy;
  }

  @override
  Widget build(BuildContext context) {
    final sorted = _sorted;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: FadeTransition(
        opacity: CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: AppColors.textOnDark, size: 20),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Top Riders',
                            style: GoogleFonts.sora(
                              color: AppColors.textOnDark,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            'Highest rated boda riders in Rwanda',
                            style: GoogleFonts.sora(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: AppColors.gold.withOpacity(0.3)),
                      ),
                      child: const Icon(Icons.emoji_events_rounded,
                          color: AppColors.gold, size: 22),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Sort tabs
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.cardDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderDark),
                  ),
                  child: Row(
                    children: [
                      _SortTab(label: '⭐ Rating', value: 'rating', current: _sortBy,
                          onTap: (v) => setState(() => _sortBy = v)),
                      _SortTab(label: '🚀 Trips', value: 'trips', current: _sortBy,
                          onTap: (v) => setState(() => _sortBy = v)),
                      _SortTab(label: '💰 Earnings', value: 'earnings', current: _sortBy,
                          onTap: (v) => setState(() => _sortBy = v)),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Podium (top 3)
              if (!_loading && sorted.length >= 3)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _Podium(riders: sorted.take(3).toList()),
                ),

              if (!_loading && sorted.length >= 3) const SizedBox(height: 16),

              // Full list
              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                          strokeWidth: 2,
                        ),
                      )
                    : sorted.isEmpty
                        ? _EmptyState()
                        : RefreshIndicator(
                            color: AppColors.primary,
                            backgroundColor: AppColors.cardDark,
                            onRefresh: _load,
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
                              itemCount: sorted.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (_, i) => _RiderCard(
                                rider: sorted[i],
                                rank: i + 1,
                              ),
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Sort Tab ───────────────────────────────────────────────────────────────────
class _SortTab extends StatelessWidget {
  final String label;
  final String value;
  final String current;
  final ValueChanged<String> onTap;

  const _SortTab({
    required this.label,
    required this.value,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final active = value == current;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(4),
          decoration: active
              ? BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(8),
                )
              : null,
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.sora(
                fontSize: 11,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                color: active ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Podium ─────────────────────────────────────────────────────────────────────
class _Podium extends StatelessWidget {
  final List<Map<String, dynamic>> riders;
  const _Podium({required this.riders});

  @override
  Widget build(BuildContext context) {
    // Order: 2nd, 1st, 3rd
    final order = [riders[1], riders[0], riders[2]];
    final heights = [90.0, 120.0, 70.0];
    final medals = [
      const Color(0xFFC0C0C0), // silver
      AppColors.gold,           // gold
      const Color(0xFFCD7F32),  // bronze
    ];
    final ranks = ['2nd', '1st', '3rd'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(3, (i) {
          final rider = order[i];
          final name = (rider['name'] as String? ?? '').split(' ').first;
          final rating = (rider['rating'] as num?)?.toStringAsFixed(1) ?? '0.0';
          return Expanded(
            child: Column(
              children: [
                // Avatar
                Container(
                  width: i == 1 ? 60 : 50,
                  height: i == 1 ? 60 : 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [medals[i], medals[i].withOpacity(0.6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: medals[i].withOpacity(0.4),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: GoogleFonts.sora(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: i == 1 ? 22 : 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  name,
                  style: GoogleFonts.sora(
                    color: AppColors.textOnDark,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.star_rounded, color: medals[i], size: 12),
                    const SizedBox(width: 2),
                    Text(
                      rating,
                      style: GoogleFonts.sora(
                        color: medals[i],
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Podium bar
                Container(
                  height: heights[i],
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        medals[i].withOpacity(0.3),
                        medals[i].withOpacity(0.1),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    ),
                    border: Border.all(
                      color: medals[i].withOpacity(0.3),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      ranks[i],
                      style: GoogleFonts.sora(
                        color: medals[i],
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

// ── Rider Card ─────────────────────────────────────────────────────────────────
class _RiderCard extends StatelessWidget {
  final Map<String, dynamic> rider;
  final int rank;
  const _RiderCard({required this.rider, required this.rank});

  Color get _rankColor {
    if (rank == 1) return AppColors.gold;
    if (rank == 2) return const Color(0xFFC0C0C0);
    if (rank == 3) return const Color(0xFFCD7F32);
    return AppColors.textSecondary;
  }

  @override
  Widget build(BuildContext context) {
    final name = rider['name'] as String? ?? 'Unknown';
    final rating = (rider['rating'] as num?)?.toStringAsFixed(1) ?? '0.0';
    final ratingCount = rider['ratingCount'] as int? ?? 0;
    final totalRides = rider['totalRides'] as int? ?? 0;
    final fiveStarCount = rider['fiveStarCount'] as int? ?? 0;
    final topTags = (rider['topTags'] as List?)?.cast<String>() ?? [];
    final isOnline = rider['isOnline'] as bool? ?? false;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: rank <= 3
              ? _rankColor.withOpacity(0.3)
              : AppColors.borderDark,
        ),
      ),
      child: Row(
        children: [
          // Rank badge
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _rankColor.withOpacity(0.12),
              shape: BoxShape.circle,
              border: Border.all(color: _rankColor.withOpacity(0.3)),
            ),
            child: Center(
              child: Text(
                '#$rank',
                style: GoogleFonts.sora(
                  color: _rankColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Avatar
          Stack(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.primaryGradient,
                ),
                child: Center(
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: GoogleFonts.sora(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              if (isOnline)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: AppColors.cardDark, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: GoogleFonts.sora(
                          color: AppColors.textOnDark,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isOnline) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Text(
                          'Online',
                          style: GoogleFonts.sora(
                            color: AppColors.success,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        color: AppColors.gold, size: 13),
                    const SizedBox(width: 3),
                    Text(
                      '$rating',
                      style: GoogleFonts.sora(
                        color: AppColors.gold,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      ' ($ratingCount ratings)',
                      style: GoogleFonts.sora(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(Icons.electric_moped_rounded,
                        color: AppColors.primary, size: 13),
                    const SizedBox(width: 3),
                    Text(
                      '$totalRides trips',
                      style: GoogleFonts.sora(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                if (topTags.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 4,
                    children: topTags.take(3).map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(50),
                          border: Border.all(
                              color: AppColors.primary.withOpacity(0.2)),
                        ),
                        child: Text(
                          tag,
                          style: GoogleFonts.sora(
                            color: AppColors.primary,
                            fontSize: 10,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(width: 8),

          // 5-star count
          Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.gold.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded,
                        color: AppColors.gold, size: 12),
                    const SizedBox(width: 3),
                    Text(
                      '$fiveStarCount',
                      style: GoogleFonts.sora(
                        color: AppColors.gold,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '5-star',
                style: GoogleFonts.sora(
                  color: AppColors.textSecondary,
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Empty State ────────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.emoji_events_outlined,
              color: AppColors.textSecondary, size: 64),
          const SizedBox(height: 16),
          Text(
            'No ratings yet',
            style: GoogleFonts.sora(
              color: AppColors.textOnDark,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Complete a ride and rate your rider\nto see the leaderboard.',
            textAlign: TextAlign.center,
            style: GoogleFonts.sora(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
