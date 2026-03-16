class RideModel {
  final String id;
  final String passengerId;
  final String? driverId;
  final LocationPoint pickup;
  final LocationPoint destination;
  final String status; // pending|accepted|arriving|in_progress|completed|cancelled
  final double price;
  final double distance;
  final int? estimatedMinutes;
  final String? rideType; // economy|premium
  final String? cancelReason;
  final int? rating;
  final String? ratingComment;
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;

  // Nested passenger/driver info (populated from API)
  final Map<String, dynamic>? passenger;
  final Map<String, dynamic>? driver;

  RideModel({
    required this.id,
    required this.passengerId,
    this.driverId,
    required this.pickup,
    required this.destination,
    required this.status,
    required this.price,
    required this.distance,
    this.estimatedMinutes,
    this.rideType = 'economy',
    this.cancelReason,
    this.rating,
    this.ratingComment,
    required this.createdAt,
    this.acceptedAt,
    this.startedAt,
    this.completedAt,
    this.passenger,
    this.driver,
  });

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isArriving => status == 'arriving';
  bool get isInProgress => status == 'in_progress';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';
  bool get isActive => ['pending', 'accepted', 'arriving', 'in_progress'].contains(status);

  factory RideModel.fromJson(Map<String, dynamic> json) {
    return RideModel(
      id: json['_id'] ?? json['id'] ?? '',
      passengerId: json['passenger'] is Map
          ? json['passenger']['_id'] ?? ''
          : json['passenger'] ?? '',
      driverId: json['driver'] is Map
          ? json['driver']['_id']
          : json['driver'],
      pickup: LocationPoint.fromJson(json['pickup']),
      destination: LocationPoint.fromJson(json['destination']),
      status: json['status'] ?? 'pending',
      price: (json['price'] ?? 0).toDouble(),
      distance: (json['distance'] ?? 0).toDouble(),
      estimatedMinutes: json['estimatedMinutes'],
      rideType: json['rideType'] ?? 'economy',
      cancelReason: json['cancelReason'],
      rating: json['rating'],
      ratingComment: json['ratingComment'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      acceptedAt: json['acceptedAt'] != null ? DateTime.parse(json['acceptedAt']) : null,
      startedAt: json['startedAt'] != null ? DateTime.parse(json['startedAt']) : null,
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
      passenger: json['passenger'] is Map ? Map<String, dynamic>.from(json['passenger']) : null,
      driver: json['driver'] is Map ? Map<String, dynamic>.from(json['driver']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'passenger': passengerId,
      'driver': driverId,
      'pickup': pickup.toJson(),
      'destination': destination.toJson(),
      'status': status,
      'price': price,
      'distance': distance,
      'estimatedMinutes': estimatedMinutes,
      'rideType': rideType,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class LocationPoint {
  final String address;
  final double lat;
  final double lng;

  LocationPoint({
    required this.address,
    required this.lat,
    required this.lng,
  });

  factory LocationPoint.fromJson(Map<String, dynamic> json) {
    return LocationPoint(
      address: json['address'] ?? '',
      lat: (json['lat'] ?? json['coordinates']?[1] ?? 0).toDouble(),
      lng: (json['lng'] ?? json['coordinates']?[0] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'address': address,
      'lat': lat,
      'lng': lng,
    };
  }
}
