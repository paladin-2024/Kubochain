import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/location_service.dart';
import '../../models/ride_model.dart';
import '../../providers/location_provider.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/map/live_map_widget.dart';
import 'choose_rider_screen.dart';

class BookRideScreen extends StatefulWidget {
  const BookRideScreen({super.key});

  @override
  State<BookRideScreen> createState() => _BookRideScreenState();
}

class _BookRideScreenState extends State<BookRideScreen> {
  final _destinationCtrl = TextEditingController();
  final MapController _mapController = MapController();

  LocationPoint? _pickup;
  LocationPoint? _destination;
  List<PlaceResult> _suggestions = [];
  bool _searchingDest = false;
  List<LatLng> _routePoints = [];
  double _estimatedPrice = 0;
  double _estimatedDistance = 0;
  String _selectedRideType = 'economy';
  bool _showConfirm = false;
  bool _isLoadingRoute = false;

  static const _rideTypes = [
    {'type': 'economy', 'label': 'Economy', 'icon': Icons.directions_bike, 'multiplier': 1.0},
    {'type': 'premium', 'label': 'Premium', 'icon': Icons.electric_bike, 'multiplier': 1.5},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initPickup();
    });
  }

  Future<void> _initPickup() async {
    final loc = context.read<LocationProvider>();
    if (loc.currentLocation != null) {
      _pickup = LocationPoint(
        address: loc.currentAddress,
        lat: loc.currentLocation!.latitude,
        lng: loc.currentLocation!.longitude,
      );
      setState(() {});
    }
  }

  Future<void> _searchDestination(String query) async {
    if (query.length < 3) return;
    setState(() => _searchingDest = true);
    final results = await LocationService.searchPlaces(query);
    setState(() {
      _suggestions = results;
      _searchingDest = false;
    });
  }

  Future<void> _selectDestination(PlaceResult place) async {
    _destination = LocationPoint(
      address: place.displayName,
      lat: place.lat,
      lng: place.lng,
    );
    _destinationCtrl.text = place.displayName.split(',').first;
    _suggestions = [];
    setState(() => _isLoadingRoute = true);

    if (_pickup != null) {
      final from = LatLng(_pickup!.lat, _pickup!.lng);
      final to = LatLng(_destination!.lat, _destination!.lng);
      _routePoints = await LocationService.getRoute(from, to);
      _estimatedDistance = LocationService.distanceKm(from, to);
      _estimatedPrice = LocationService.estimatePrice(_estimatedDistance);
    }

    setState(() {
      _isLoadingRoute = false;
      _showConfirm = true;
    });

    if (_routePoints.length > 1) {
      _mapController.move(LatLng(_pickup!.lat, _pickup!.lng), 13);
    }
  }

  void _bookRide() {
    if (_pickup == null || _destination == null) return;
    final multiplier = (_rideTypes.firstWhere(
                (r) => r['type'] == _selectedRideType)['multiplier']
            as num)
        .toDouble();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChooseRiderScreen(
          pickup: LatLng(_pickup!.lat, _pickup!.lng),
          destination: LatLng(_destination!.lat, _destination!.lng),
          pickupAddress: _pickup!.address,
          destinationAddress: _destination!.address,
          estimatedPrice: _estimatedPrice * multiplier,
          distanceKm: _estimatedDistance,
          routePoints: _routePoints,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _destinationCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pickup = _pickup;
    final dest = _destination;
    final center = pickup != null
        ? LatLng(pickup.lat, pickup.lng)
        : AppConstants.defaultLocation;

    return Scaffold(
      body: Stack(
        children: [
          LiveMapWidget(
            center: center,
            pickupLocation: pickup != null ? LatLng(pickup.lat, pickup.lng) : null,
            destinationLocation: dest != null ? LatLng(dest.lat, dest.lng) : null,
            routePoints: _routePoints,
            mapController: _mapController,
          ),

          // Top search panel
          SafeArea(
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 12)],
                  ),
                  child: Column(
                    children: [
                      // Back + title
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Plan your ride',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Route indicator
                      Row(
                        children: [
                          Column(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Container(width: 2, height: 28, color: AppColors.border),
                              Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  color: AppColors.error,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              children: [
                                // Pickup
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: AppColors.backgroundLight,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          pickup?.address.split(',').first ?? 'Getting location...',
                                          style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 6),
                                // Destination
                                TextField(
                                  controller: _destinationCtrl,
                                  onChanged: _searchDestination,
                                  style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                                  decoration: InputDecoration(
                                    hintText: 'Where to?',
                                    hintStyle: const TextStyle(color: AppColors.textHint),
                                    filled: true,
                                    fillColor: AppColors.backgroundLight,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    suffixIcon: _searchingDest
                                        ? const Padding(
                                            padding: EdgeInsets.all(12),
                                            child: SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(strokeWidth: 2),
                                            ),
                                          )
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Search suggestions
                if (_suggestions.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _suggestions.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (ctx, i) {
                        final place = _suggestions[i];
                        return ListTile(
                          leading: const Icon(Icons.location_on_outlined, color: AppColors.primary),
                          title: Text(
                            place.displayName.split(',').first,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                          subtitle: Text(
                            place.displayName.split(',').skip(1).take(2).join(',').trim(),
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () => _selectDestination(place),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          // Loading route indicator
          if (_isLoadingRoute)
            const Center(child: CircularProgressIndicator()),

          // Bottom confirm panel
          if (_showConfirm && !_isLoadingRoute)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 16)],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Trip info
                    Row(
                      children: [
                        const Icon(Icons.route, color: AppColors.primary, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '${_estimatedDistance.toStringAsFixed(1)} km',
                          style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                        ),
                        const SizedBox(width: 16),
                        const Icon(Icons.access_time, color: AppColors.textSecondary, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '~${(_estimatedDistance * 4).ceil()} min',
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Ride type selection
                    const Text(
                      'Choose ride type',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: _rideTypes.map((rt) {
                        final selected = _selectedRideType == rt['type'];
                        final mult = (rt['multiplier'] as num).toDouble();
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedRideType = rt['type'] as String),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: selected ? AppColors.primary.withOpacity(0.08) : AppColors.backgroundLight,
                                border: Border.all(
                                  color: selected ? AppColors.primary : AppColors.border,
                                  width: selected ? 2 : 1,
                                ),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Column(
                                children: [
                                  Icon(rt['icon'] as IconData, color: selected ? AppColors.primary : AppColors.textSecondary, size: 28),
                                  const SizedBox(height: 6),
                                  Text(rt['label'] as String,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                        color: selected ? AppColors.primary : AppColors.textSecondary,
                                      )),
                                  const SizedBox(height: 4),
                                  Text(
                                    'FC ${(_estimatedPrice * mult).toStringAsFixed(0)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: selected ? AppColors.primary : AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    AppButton(
                      label: 'Find Now',
                      onPressed: _bookRide,
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
