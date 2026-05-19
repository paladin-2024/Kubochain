import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/api_service.dart';
import '../../models/ride_model.dart';
import '../../providers/providers.dart';
import 'booking_success_screen.dart';

class ChooseRiderScreen extends ConsumerStatefulWidget {
  final LatLng pickup;
  final LatLng destination;
  final String pickupAddress;
  final String destinationAddress;
  final double estimatedPrice;
  final double distanceKm;
  final List<LatLng> routePoints;

  const ChooseRiderScreen({
    super.key,
    required this.pickup,
    required this.destination,
    required this.pickupAddress,
    required this.destinationAddress,
    required this.estimatedPrice,
    required this.distanceKm,
    required this.routePoints,
  });

  @override
  ConsumerState<ChooseRiderScreen> createState() => _ChooseRiderScreenState();
}

class _ChooseRiderScreenState extends ConsumerState<ChooseRiderScreen>
    with TickerProviderStateMixin {
  List<dynamic> _drivers = [];
  String _selectedType = 'economy';
  bool _loading = true;
  late AnimationController _sheetCtrl;
  late Animation<Offset> _sheetSlide;
  bool _confirming = false;

  @override
  void initState() {
    super.initState();
    _sheetCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _sheetSlide = Tween<Offset>(
      begin: const Offset(0, 1), end: Offset.zero,
    ).animate(CurvedAnimation(parent: _sheetCtrl, curve: Curves.easeOutCubic));
    _loadDrivers();
  }

  Future<void> _loadDrivers() async {
    try {
      final res = await ApiService.getNearbyDrivers(
        lat: widget.pickup.latitude, lng: widget.pickup.longitude);
      setState(() {
        _drivers = res.data['drivers'] ?? [];
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
    _sheetCtrl.forward();
  }

  double get _premiumPrice => widget.estimatedPrice * 1.4;

  Future<void> _confirmRide() async {
    if (_confirming) return;
    HapticFeedback.mediumImpact();
    setState(() => _confirming = true);
    final ride = ref.read(rideProvider);
    await ride.requestRide(
      pickup: LocationPoint(
        address: widget.pickupAddress,
        lat: widget.pickup.latitude,
        lng: widget.pickup.longitude,
      ),
      destination: LocationPoint(
        address: widget.destinationAddress,
        lat: widget.destination.latitude,
        lng: widget.destination.longitude,
      ),
      rideType: _selectedType,
      price: _selectedType == 'economy' ? widget.estimatedPrice : _premiumPrice,
      distance: widget.distanceKm,
    );
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => BookingSuccessScreen(
          rideId: ride.currentRide?.id ?? '',
          pickup: widget.pickupAddress,
          destination: widget.destinationAddress,
        ),
      ),
    );
  }

  @override
  void dispose() { _sheetCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // ── Map ─────────────────────────────────────────────
          Expanded(
            flex: 5,
            child: Stack(
              children: [
                FlutterMap(
                  options: MapOptions(
                    initialCenter: LatLng(
                      (widget.pickup.latitude + widget.destination.latitude) / 2,
                      (widget.pickup.longitude + widget.destination.longitude) / 2,
                    ),
                    initialZoom: 13,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
                      subdomains: const ['a', 'b', 'c', 'd'],
                      userAgentPackageName: 'com.kubochain.app',
                    ),
                    if (widget.routePoints.length > 1)
                      PolylineLayer(polylines: [
                        Polyline(
                          points: widget.routePoints,
                          color: AppColors.primary,
                          strokeWidth: 4.5,
                        ),
                      ]),
                    MarkerLayer(markers: [
                      Marker(
                        point: widget.pickup,
                        width: 40, height: 40,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 12)],
                          ),
                          child: const Icon(Icons.my_location_rounded, color: Colors.white, size: 18),
                        ),
                      ),
                      Marker(
                        point: widget.destination,
                        width: 40, height: 40,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D1629),
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 12)],
                          ),
                          child: const Icon(Icons.location_on_rounded, color: Colors.white, size: 18),
                        ),
                      ),
                    ]),
                  ],
                ),
                // Back button
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 12)],
                        ),
                        child: const Icon(Icons.arrow_back_rounded, size: 20),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Bottom selection sheet ───────────────────────────
          SlideTransition(
            position: _sheetSlide,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 24, offset: const Offset(0, -4)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle
                  const SizedBox(height: 12),
                  Container(
                    width: 36, height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Choose your ride',
                          style: GoogleFonts.sora(
                            fontSize: 20, fontWeight: FontWeight.w800,
                            color: const Color(0xFF0D1629),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.distanceKm.toStringAsFixed(1)} km · ${_drivers.length} drivers nearby',
                          style: GoogleFonts.dmSans(
                            fontSize: 13, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 16),

                        // Vehicle type cards
                        Row(
                          children: [
                            Expanded(child: _VehicleCard(
                              type: 'economy',
                              label: 'Economy',
                              subtitle: 'Boda-boda',
                              icon: Icons.two_wheeler_rounded,
                              price: widget.estimatedPrice,
                              minutes: (widget.distanceKm * 4).ceil(),
                              isSelected: _selectedType == 'economy',
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() => _selectedType = 'economy');
                              },
                            )),
                            const SizedBox(width: 12),
                            Expanded(child: _VehicleCard(
                              type: 'premium',
                              label: 'Premium',
                              subtitle: 'Top-rated',
                              icon: Icons.electric_moped_rounded,
                              price: _premiumPrice,
                              minutes: (widget.distanceKm * 3.5).ceil(),
                              isSelected: _selectedType == 'premium',
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() => _selectedType = 'premium');
                              },
                            )),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Nearby driver avatars
                        if (!_loading && _drivers.isNotEmpty) ...[
                          Row(
                            children: [
                              Text(
                                'Nearby drivers',
                                style: GoogleFonts.dmSans(
                                  fontSize: 13, fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                child: Text(
                                  '${_drivers.length} available',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 11, fontWeight: FontWeight.w600,
                                    color: AppColors.success),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 44,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _drivers.take(6).length,
                              itemBuilder: (ctx, i) {
                                final d = _drivers[i];
                                final name = d['firstName'] ?? d['user']?['firstName'] ?? 'D';
                                final img = d['profileImage'] ?? d['user']?['profileImage'];
                                return Container(
                                  width: 44, height: 44,
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 6)],
                                  ),
                                  child: CircleAvatar(
                                    backgroundImage: img != null
                                        ? NetworkImage(ApiService.imageUrl(img))
                                        : null,
                                    backgroundColor: AppColors.primary.withOpacity(0.15),
                                    child: img == null
                                        ? Text(name[0].toUpperCase(),
                                            style: GoogleFonts.sora(
                                              fontSize: 14, fontWeight: FontWeight.w700,
                                              color: AppColors.primary))
                                        : null,
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Route summary
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            children: [
                              _RouteRow(
                                color: AppColors.primary,
                                icon: Icons.radio_button_on_rounded,
                                label: widget.pickupAddress.split(',').first,
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 10),
                                child: Container(
                                  height: 20,
                                  width: 1.5,
                                  color: const Color(0xFFCBD5E1),
                                ),
                              ),
                              _RouteRow(
                                color: const Color(0xFF0D1629),
                                icon: Icons.location_on_rounded,
                                label: widget.destinationAddress.split(',').first,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Confirm CTA
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            child: ElevatedButton(
                              onPressed: (_loading || _confirming) ? null : _confirmRide,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(50)),
                              ),
                              child: _confirming
                                  ? const SizedBox(
                                      width: 22, height: 22,
                                      child: CircularProgressIndicator(
                                          color: Colors.white, strokeWidth: 2.5))
                                  : Text(
                                      'Confirm ${_selectedType == 'economy' ? 'Economy' : 'Premium'} Ride  ·  FC ${(_selectedType == 'economy' ? widget.estimatedPrice : _premiumPrice).toStringAsFixed(0)}',
                                      style: GoogleFonts.sora(
                                        fontSize: 15, fontWeight: FontWeight.w700,
                                        color: Colors.white),
                                    ),
                            ),
                          ),
                        ),
                        SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
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
}

// ── Vehicle card ─────────────────────────────────────────────────────────────
class _VehicleCard extends StatelessWidget {
  final String type, label, subtitle;
  final IconData icon;
  final double price;
  final int minutes;
  final bool isSelected;
  final VoidCallback onTap;

  const _VehicleCard({
    required this.type, required this.label, required this.subtitle,
    required this.icon, required this.price, required this.minutes,
    required this.isSelected, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
            width: isSelected ? 0 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(color: AppColors.primary.withOpacity(0.28), blurRadius: 16, offset: const Offset(0, 6)),
          ] : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withOpacity(0.2) : AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 24,
                  color: isSelected ? Colors.white : AppColors.primary),
            ),
            const SizedBox(height: 10),
            Text(label,
              style: GoogleFonts.sora(
                fontSize: 14, fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : const Color(0xFF0D1629))),
            Text(subtitle,
              style: GoogleFonts.dmSans(
                fontSize: 11, color: isSelected ? Colors.white70 : AppColors.textSecondary)),
            const SizedBox(height: 8),
            Text(
              'FC ${price.toStringAsFixed(0)}',
              style: GoogleFonts.sora(
                fontSize: 16, fontWeight: FontWeight.w800,
                color: isSelected ? Colors.white : AppColors.primary)),
            Text('~$minutes min',
              style: GoogleFonts.dmSans(
                fontSize: 11, color: isSelected ? Colors.white70 : AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

// ── Route row ────────────────────────────────────────────────────────────────
class _RouteRow extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;
  const _RouteRow({required this.color, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 16, color: color),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500,
              color: const Color(0xFF0D1629)),
        ),
      ),
    ],
  );
}
