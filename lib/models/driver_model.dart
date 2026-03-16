class DriverModel {
  final String id;
  final String userId;
  final String firstName;
  final String lastName;
  final String phone;
  final String? profileImage;
  final double rating;
  final int totalRides;
  final bool isOnline;
  final double? lat;
  final double? lng;
  final VehicleInfo vehicle;
  final double totalEarnings;
  final DateTime memberSince;

  DriverModel({
    required this.id,
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.phone,
    this.profileImage,
    this.rating = 5.0,
    this.totalRides = 0,
    this.isOnline = false,
    this.lat,
    this.lng,
    required this.vehicle,
    this.totalEarnings = 0,
    required this.memberSince,
  });

  String get fullName => '$firstName $lastName';

  factory DriverModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'] is Map ? json['user'] : {};
    return DriverModel(
      id: json['_id'] ?? json['id'] ?? '',
      userId: user['_id'] ?? json['user'] ?? '',
      firstName: user['firstName'] ?? json['firstName'] ?? '',
      lastName: user['lastName'] ?? json['lastName'] ?? '',
      phone: user['phone'] ?? json['phone'] ?? '',
      profileImage: user['profileImage'] ?? json['profileImage'],
      rating: (json['rating'] ?? 5.0).toDouble(),
      totalRides: json['totalRides'] ?? 0,
      isOnline: json['isOnline'] ?? false,
      lat: json['location']?['coordinates'] != null
          ? (json['location']['coordinates'][1]).toDouble()
          : json['lat']?.toDouble(),
      lng: json['location']?['coordinates'] != null
          ? (json['location']['coordinates'][0]).toDouble()
          : json['lng']?.toDouble(),
      vehicle: VehicleInfo.fromJson(json['vehicle'] ?? {}),
      totalEarnings: (json['totalEarnings'] ?? 0).toDouble(),
      memberSince: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }
}

class VehicleInfo {
  final String make;
  final String model;
  final String color;
  final String plateNumber;
  final String type; // 'motorcycle' | 'car'

  VehicleInfo({
    required this.make,
    required this.model,
    required this.color,
    required this.plateNumber,
    this.type = 'motorcycle',
  });

  String get displayName => '$color $make $model';

  factory VehicleInfo.fromJson(Map<String, dynamic> json) {
    return VehicleInfo(
      make: json['make'] ?? 'Unknown',
      model: json['model'] ?? '',
      color: json['color'] ?? '',
      plateNumber: json['plateNumber'] ?? '',
      type: json['type'] ?? 'motorcycle',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'make': make,
      'model': model,
      'color': color,
      'plateNumber': plateNumber,
      'type': type,
    };
  }
}
