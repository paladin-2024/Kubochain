import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/ride_model.dart';
import '../../providers/ride_provider.dart';
import 'book_ride_screen.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  int _filterIdx = 0; // 0=All, 1=Completed, 2=Cancelled
  static const _filters = ['All', 'Completed', 'Cancelled'];

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RideProvider>().fetchRideHistory();
    });
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  List<RideModel> _filtered(List<RideModel> all) {
    if (_filterIdx == 1) return all.where((r) => r.isCompleted).toList();
    if (_filterIdx == 2) return all.where((r) => r.isCancelled).toList();
    return all;
  }

  @override
  Widget build(BuildContext context) {
    final ride = context.watch<RideProvider>();
    final filtered = _filtered(ride.rideHistory);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: FadeTransition(
        opacity: CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut),
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'My Trips',
                            style: GoogleFonts.sora(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textOnDark,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            '${ride.rideHistory.length} total rides',
                            style: GoogleFonts.sora(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Stats pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.cardDark,
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(color: AppColors.borderDark),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.electric_moped_rounded,
                              color: AppColors.primary, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            '${ride.rideHistory.where((r) => r.isCompleted).length} done',
                            style: GoogleFonts.sora(
                              fontSize: 12,
                              color: AppColors.textOnDark,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Filter tabs
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.cardDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderDark),
                  ),
                  child: Row(
                    children: List.generate(_filters.length, (i) {
                      final active = i == _filterIdx;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _filterIdx = i),
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
                                _filters[i],
                                style: GoogleFonts.sora(
                                  fontSize: 12,
                                  fontWeight: active
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: active
                                      ? Colors.white
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // List
              Expanded(
                child: ride.isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                          strokeWidth: 2,
                        ),
                      )
                    : filtered.isEmpty
                        ? _EmptyState(filter: _filters[_filterIdx])
                        : RefreshIndicator(
                            color: AppColors.primary,
                            backgroundColor: AppColors.cardDark,
                            onRefresh: () =>
                                context.read<RideProvider>().fetchRideHistory(),
                            child: ListView.separated(
                              padding:
                                  const EdgeInsets.fromLTRB(24, 0, 24, 120),
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (ctx, i) => _HistoryCard(
                                ride: filtered[i],
                                index: i,
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

// ── Empty State ────────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final String filter;
  const _EmptyState({required this.filter});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withOpacity(0.15),
              ),
            ),
            child: const Icon(Icons.receipt_long_rounded,
                size: 40, color: AppColors.primary),
          ),
          const SizedBox(height: 20),
          Text(
            'No ${filter == "All" ? "" : "$filter "}trips yet',
            style: GoogleFonts.sora(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textOnDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your ride history will appear here.',
            style: GoogleFonts.sora(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 28),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BookRideScreen()),
            ),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(50),
                boxShadow: AppColors.primaryGlow,
              ),
              child: Text(
                'Book a Ride',
                style: GoogleFonts.sora(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── History Card ───────────────────────────────────────────────────────────────
class _HistoryCard extends StatelessWidget {
  final RideModel ride;
  final int index;
  const _HistoryCard({required this.ride, required this.index});

  Color get _statusColor {
    if (ride.isCompleted) return AppColors.success;
    if (ride.isCancelled) return AppColors.error;
    if (ride.isInProgress) return AppColors.primary;
    return AppColors.warning;
  }

  String get _statusLabel {
    if (ride.isCompleted) return 'Completed';
    if (ride.isCancelled) return 'Cancelled';
    if (ride.isInProgress) return 'In Progress';
    if (ride.isArriving) return 'Arriving';
    if (ride.isAccepted) return 'Accepted';
    return 'Pending';
  }

  void _showDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RideDetailSheet(ride: ride),
    );
  }

  @override
  Widget build(BuildContext context) {
    final driverName = ride.driver != null
        ? ('${ride.driver!['firstName'] ?? ride.driver!['user']?['firstName'] ?? ''} '
                '${ride.driver!['lastName'] ?? ride.driver!['user']?['lastName'] ?? ''}')
            .trim()
        : 'Pending';

    final months = [
      '',
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    final dt = ride.createdAt;
    final dateStr =
        '${dt.day} ${months[dt.month]}, ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';

    return GestureDetector(
      onTap: () => _showDetails(context),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderDark),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Route thumbnail
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceDark,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.borderDark),
                    ),
                    child: CustomPaint(
                      painter: _DarkRoutePainter(_statusColor),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: _statusColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(50),
                                border: Border.all(
                                    color: _statusColor.withOpacity(0.25)),
                              ),
                              child: Text(
                                _statusLabel,
                                style: GoogleFonts.sora(
                                  color: _statusColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              dateStr,
                              style: GoogleFonts.sora(
                                fontSize: 10,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Route with timeline dots
                        _TinyRouteRow(
                          icon: Icons.radio_button_checked,
                          color: AppColors.primary,
                          address: ride.pickup.address,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 9),
                          child: Column(
                            children: List.generate(
                              2,
                              (_) => Container(
                                width: 1.5,
                                height: 4,
                                margin:
                                    const EdgeInsets.symmetric(vertical: 1.5),
                                color: AppColors.borderDark,
                              ),
                            ),
                          ),
                        ),
                        _TinyRouteRow(
                          icon: Icons.location_on_rounded,
                          color: AppColors.error,
                          address: ride.destination.address,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(height: 1, color: AppColors.borderDark),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _CardStat(
                    label: 'Driver',
                    value: driverName.isEmpty ? 'Pending' : driverName,
                  ),
                  _CardStat(
                    label: 'Distance',
                    value: '${ride.distance.toStringAsFixed(1)} km',
                  ),
                  _CardStat(
                    label: 'Fare',
                    value: 'FC ${ride.price.toStringAsFixed(0)}',
                    valueColor: AppColors.success,
                    bold: true,
                  ),
                  const Icon(Icons.chevron_right,
                      color: AppColors.textSecondary, size: 18),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TinyRouteRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String address;

  const _TinyRouteRow({
    required this.icon,
    required this.color,
    required this.address,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            address,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.sora(
              fontSize: 12,
              color: AppColors.textOnDark.withOpacity(0.8),
            ),
          ),
        ),
      ],
    );
  }
}

class _CardStat extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool bold;

  const _CardStat({
    required this.label,
    required this.value,
    this.valueColor,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.sora(
            fontSize: 10,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.sora(
            fontSize: 12,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            color: valueColor ?? AppColors.textOnDark,
          ),
        ),
      ],
    );
  }
}

// ── Ride Detail Sheet ──────────────────────────────────────────────────────────
class _RideDetailSheet extends StatelessWidget {
  final RideModel ride;
  const _RideDetailSheet({required this.ride});

  Color get _statusColor {
    if (ride.isCompleted) return AppColors.success;
    if (ride.isCancelled) return AppColors.error;
    if (ride.isInProgress) return AppColors.primary;
    return AppColors.warning;
  }

  String get _statusLabel {
    if (ride.isCompleted) return 'Completed';
    if (ride.isCancelled) return 'Cancelled';
    if (ride.isInProgress) return 'In Progress';
    if (ride.isArriving) return 'Arriving';
    if (ride.isAccepted) return 'Accepted';
    return 'Pending';
  }

  String _formatDt(DateTime dt) {
    final months = [
      '','Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return '${dt.day} ${months[dt.month]} ${dt.year}, ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String get _duration {
    if (ride.startedAt != null && ride.completedAt != null) {
      final diff = ride.completedAt!.difference(ride.startedAt!);
      return '${diff.inMinutes} min';
    }
    return '—';
  }

  String get _driverName {
    final fn = ride.driver?['user']?['firstName'] ?? ride.driver?['firstName'] ?? '';
    final ln = ride.driver?['user']?['lastName'] ?? ride.driver?['lastName'] ?? '';
    return '$fn $ln'.trim();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            // Handle
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderDark,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                children: [
                  // Status + title
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _statusColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(50),
                          border: Border.all(
                              color: _statusColor.withOpacity(0.3)),
                        ),
                        child: Text(
                          _statusLabel,
                          style: GoogleFonts.sora(
                            color: _statusColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _formatDt(ride.createdAt),
                        style: GoogleFonts.sora(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Fare highlight
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.success.withOpacity(0.12),
                          AppColors.primary.withOpacity(0.06),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AppColors.success.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.account_balance_wallet_rounded,
                            color: AppColors.success, size: 28),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Fare',
                              style: GoogleFonts.sora(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              'FC ${ride.price.toStringAsFixed(0)}',
                              style: GoogleFonts.sora(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: AppColors.success,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: ride.isCompleted
                                ? AppColors.success.withOpacity(0.1)
                                : AppColors.borderDark,
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: Text(
                            ride.isCompleted ? 'Paid' : 'Unpaid',
                            style: GoogleFonts.sora(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: ride.isCompleted
                                  ? AppColors.success
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Route
                  _DarkSection(
                    title: 'Route',
                    child: Column(
                      children: [
                        _DarkDetailRow(
                          iconWidget: const Icon(Icons.radio_button_checked,
                              color: AppColors.primary, size: 18),
                          label: 'Pickup',
                          value: ride.pickup.address,
                        ),
                        const SizedBox(height: 12),
                        _DarkDetailRow(
                          iconWidget: const Icon(Icons.location_on_rounded,
                              color: AppColors.error, size: 18),
                          label: 'Destination',
                          value: ride.destination.address,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Trip details
                  _DarkSection(
                    title: 'Trip Details',
                    child: Column(
                      children: [
                        _SheetRow(
                            label: 'Distance',
                            value: '${ride.distance.toStringAsFixed(1)} km'),
                        _SheetRow(
                            label: 'Duration', value: _duration),
                        _SheetRow(
                            label: 'Ride Type',
                            value: ride.rideType == 'premium'
                                ? 'Premium'
                                : 'Economy'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Driver
                  if (ride.driver != null)
                    _DarkSection(
                      title: 'Driver',
                      child: Column(
                        children: [
                          // Avatar row
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor:
                                    AppColors.primary.withOpacity(0.15),
                                child: Text(
                                  (_driverName.isNotEmpty
                                      ? _driverName[0]
                                      : 'D'),
                                  style: GoogleFonts.sora(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _driverName.isEmpty
                                        ? 'Unknown'
                                        : _driverName,
                                    style: GoogleFonts.sora(
                                      color: AppColors.textOnDark,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      const Icon(Icons.star_rounded,
                                          color: AppColors.gold, size: 14),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${ride.driver?['user']?['rating'] ?? ride.driver?['rating'] ?? '5.0'}',
                                        style: GoogleFonts.sora(
                                          color: AppColors.textSecondary,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _SheetRow(
                              label: 'Vehicle',
                              value:
                                  '${ride.driver?['vehicle']?['color'] ?? ''} ${ride.driver?['vehicle']?['make'] ?? ''}'
                                      .trim()),
                          _SheetRow(
                              label: 'Plate',
                              value:
                                  ride.driver?['vehicle']?['plateNumber'] ??
                                      '—'),
                        ],
                      ),
                    ),

                  // Rating
                  if (ride.isCompleted && (ride.rating ?? 0) > 0) ...[
                    const SizedBox(height: 12),
                    _DarkSection(
                      title: 'Your Rating',
                      child: Row(
                        children: List.generate(
                          5,
                          (i) => Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Icon(
                              i < (ride.rating ?? 0)
                                  ? Icons.star_rounded
                                  : Icons.star_border_rounded,
                              color: AppColors.gold,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),

                  // Book Again
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: AppColors.primaryGlow,
                    ),
                    child: TextButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const BookRideScreen()),
                        );
                      },
                      icon: const Icon(Icons.electric_moped_rounded,
                          color: Colors.white, size: 18),
                      label: Text(
                        'Book Again',
                        style: GoogleFonts.sora(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
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
}

class _DarkSection extends StatelessWidget {
  final String title;
  final Widget child;
  const _DarkSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: GoogleFonts.sora(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _DarkDetailRow extends StatelessWidget {
  final Widget iconWidget;
  final String label;
  final String value;
  const _DarkDetailRow(
      {required this.iconWidget, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        iconWidget,
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.sora(
                    fontSize: 10, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.sora(
                    fontSize: 13, color: AppColors.textOnDark),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SheetRow extends StatelessWidget {
  final String label;
  final String value;
  const _SheetRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.sora(
                fontSize: 13, color: AppColors.textSecondary),
          ),
          Text(
            value,
            style: GoogleFonts.sora(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textOnDark,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Dark Route Painter ─────────────────────────────────────────────────────────
class _DarkRoutePainter extends CustomPainter {
  final Color color;
  _DarkRoutePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.6)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final path = ui.Path()
      ..moveTo(size.width * 0.25, size.height * 0.75)
      ..cubicTo(
          size.width * 0.25, size.height * 0.4,
          size.width * 0.75, size.height * 0.6,
          size.width * 0.75, size.height * 0.25);
    canvas.drawPath(path, paint);
    final dot = Paint()..color = AppColors.primary;
    canvas.drawCircle(
        Offset(size.width * 0.25, size.height * 0.75), 3.5, dot);
    dot.color = AppColors.error;
    canvas.drawCircle(
        Offset(size.width * 0.75, size.height * 0.25), 3.5, dot);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
