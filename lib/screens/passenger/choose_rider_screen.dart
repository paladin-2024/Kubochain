import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/api_service.dart';
import '../../models/ride_model.dart';
import '../../providers/ride_provider.dart';
import 'booking_success_screen.dart';

class ChooseRiderScreen extends StatefulWidget {
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
  State<ChooseRiderScreen> createState() => _ChooseRiderScreenState();
}

class _ChooseRiderScreenState extends State<ChooseRiderScreen> {
  List<dynamic> _drivers = [];
  int _selectedIndex = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadNearbyDrivers();
  }

  Future<void> _loadNearbyDrivers() async {
    try {
      final res = await ApiService.getNearbyDrivers(
        lat: widget.pickup.latitude,
        lng: widget.pickup.longitude,
      );
      setState(() {
        _drivers = res.data['drivers'] ?? [];
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  void _showRideInfo() {
    if (_drivers.isEmpty) return;
    final driver = _drivers[_selectedIndex];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _RideInfoSheet(
        driver: driver,
        price: widget.estimatedPrice,
        pickupAddress: widget.pickupAddress,
        destinationAddress: widget.destinationAddress,
        onConfirm: _confirmRide,
      ),
    );
  }

  Future<void> _confirmRide() async {
    Navigator.pop(context); // close bottom sheet
    final rideProvider = context.read<RideProvider>();
    await rideProvider.requestRide(
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
      rideType: 'economy',
      price: widget.estimatedPrice,
      distance: widget.distanceKm,
    );

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => BookingSuccessScreen(
          rideId: rideProvider.currentRide?.id ?? '',
          pickup: widget.pickupAddress,
          destination: widget.destinationAddress,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // ── Map ───────────────────────────────────────────
          Expanded(
            flex: 5,
            child: Stack(
              children: [
                FlutterMap(
                  options: MapOptions(
                    initialCenter: widget.pickup,
                    initialZoom: 13,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                      subdomains: const ['a', 'b', 'c', 'd'],
                      userAgentPackageName: 'com.kubochain.app',
                    ),
                    if (widget.routePoints.length > 1)
                      PolylineLayer(polylines: [
                        Polyline(
                          points: widget.routePoints,
                          color: AppColors.primary,
                          strokeWidth: 4,
                        ),
                      ]),
                    MarkerLayer(markers: [
                      Marker(
                        point: widget.pickup,
                        width: 32,
                        height: 32,
                        child: Container(
                          decoration: const BoxDecoration(
                              color: AppColors.primary, shape: BoxShape.circle),
                          child: const Icon(Icons.my_location,
                              color: Colors.white, size: 16),
                        ),
                      ),
                      Marker(
                        point: widget.destination,
                        width: 32,
                        height: 32,
                        child: Container(
                          decoration: BoxDecoration(
                              color: Colors.grey.shade800,
                              shape: BoxShape.circle),
                          child: const Icon(Icons.location_on,
                              color: Colors.white, size: 16),
                        ),
                      ),
                    ]),
                  ],
                ),
                // Back + title
                SafeArea(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                                color: Colors.white, shape: BoxShape.circle),
                            child: const Icon(Icons.arrow_back_rounded,
                                size: 20),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Choose a Rider',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Driver list ────────────────────────────────────
          Expanded(
            flex: 7,
            child: Column(
              children: [
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _drivers.isEmpty
                          ? const Center(
                              child: Text('No drivers nearby',
                                  style: TextStyle(color: Colors.grey)))
                          : ListView.builder(
                              itemCount: _drivers.length,
                              itemBuilder: (ctx, i) {
                                final d = _drivers[i];
                                final isSelected = i == _selectedIndex;
                                return GestureDetector(
                                  onTap: () =>
                                      setState(() => _selectedIndex = i),
                                  child: Container(
                                    color: isSelected
                                        ? AppColors.primary.withOpacity(0.05)
                                        : Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 12),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 24,
                                          backgroundImage: d['user']
                                                      ?['profileImage'] !=
                                                  null
                                              ? NetworkImage(ApiService.imageUrl(
                                                  d['user']['profileImage']))
                                              : null,
                                          child: d['user']?['profileImage'] ==
                                                  null
                                              ? Text(
                                                  (d['user']?['firstName'] ??
                                                      'D')[0],
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold))
                                              : null,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '${d['user']?['firstName'] ?? ''} ${d['user']?['lastName'] ?? ''}',
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 15),
                                              ),
                                              const SizedBox(height: 4),
                                              Row(children: [
                                                const Icon(Icons.star,
                                                    color: Colors.orange,
                                                    size: 14),
                                                Text(
                                                    ' ${d['rating'] ?? '4.9'} · ',
                                                    style: const TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey)),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.all(2),
                                                  decoration:
                                                      const BoxDecoration(
                                                    color: Color(0xFFE3F2E8),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Icon(
                                                      Icons.attach_money,
                                                      size: 12,
                                                      color: Color(0xFF34C759)),
                                                ),
                                                Text(
                                                  ' FC ${widget.estimatedPrice.toStringAsFixed(0)}  ·  10 min  ·  4 Seats',
                                                  style: const TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey),
                                                ),
                                              ]),
                                            ],
                                          ),
                                        ),
                                        const Icon(Icons.two_wheeler,
                                            size: 36, color: Colors.black54),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                ),
                // Select Ride button
                Padding(
                  padding:
                      const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _drivers.isEmpty ? null : _showRideInfo,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30)),
                      ),
                      child: const Text(
                        'Select Ride',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600),
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

// ── Bottom Sheet ────────────────────────────────────────────────────────────
class _RideInfoSheet extends StatelessWidget {
  final dynamic driver;
  final double price;
  final String pickupAddress;
  final String destinationAddress;
  final VoidCallback onConfirm;

  const _RideInfoSheet({
    required this.driver,
    required this.price,
    required this.pickupAddress,
    required this.destinationAddress,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final name =
        '${driver['user']?['firstName'] ?? ''} ${driver['user']?['lastName'] ?? ''}';
    final rating = driver['rating']?.toString() ?? '4.9';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Ride Information',
                  style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Driver photo
          CircleAvatar(
            radius: 44,
            backgroundImage:
                driver['user']?['profileImage'] != null
                    ? NetworkImage(
                        ApiService.imageUrl(driver['user']['profileImage']))
                    : null,
            child: driver['user']?['profileImage'] == null
                ? Text(name.isNotEmpty ? name[0] : 'D',
                    style: const TextStyle(
                        fontSize: 32, fontWeight: FontWeight.bold))
                : null,
          ),
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(name,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 17)),
            const SizedBox(width: 6),
            const Icon(Icons.star, color: Colors.orange, size: 16),
            Text(' $rating',
                style:
                    const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
          ]),
          const SizedBox(height: 16),
          // Price + time
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F2F7),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(children: [
              _InfoRow(
                  label: 'Ride Price',
                  value: 'FC ${price.toStringAsFixed(0)}',
                  valueColor: const Color(0xFF34C759)),
              const Divider(height: 16),
              const _InfoRow(label: 'Pickup time', value: '10 Min'),
            ]),
          ),
          const SizedBox(height: 14),
          // Addresses
          _AddressRow(icon: Icons.arrow_right_alt_rounded, address: pickupAddress),
          const SizedBox(height: 8),
          _AddressRow(icon: Icons.location_on_outlined, address: destinationAddress),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: onConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ),
              child: const Text('Confirm Ride',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _InfoRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.grey, fontSize: 14)),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: valueColor ?? Colors.black)),
        ],
      );
}

class _AddressRow extends StatelessWidget {
  final IconData icon;
  final String address;
  const _AddressRow({required this.icon, required this.address});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 18, color: Colors.black54),
          const SizedBox(width: 8),
          Expanded(
            child: Text(address,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14)),
          ),
        ],
      );
}
