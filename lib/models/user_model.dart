class UserModel {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String role;
  final String? profileImage;
  final double rating;
  final int totalRides;
  final DateTime createdAt;
  final bool isVerified;

  UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.role,
    this.profileImage,
    this.rating = 5.0,
    this.totalRides = 0,
    required this.createdAt,
    this.isVerified = true,
  });

  String get fullName => '$firstName $lastName';

  UserModel copyWith({
    String? profileImage,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    bool? isVerified,
  }) {
    return UserModel(
      id: id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role,
      profileImage: profileImage ?? this.profileImage,
      rating: rating,
      totalRides: totalRides,
      createdAt: createdAt,
      isVerified: isVerified ?? this.isVerified,
    );
  }

  // Handles both FastAPI snake_case and legacy camelCase field names.
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      firstName: json['first_name'] ?? json['firstName'] ?? '',
      lastName:  json['last_name']  ?? json['lastName']  ?? '',
      email:     json['email'] ?? '',
      phone:     json['phone'] ?? '',
      role:      json['role']  ?? 'passenger',
      profileImage: json['profile_image'] ?? json['profileImage'],
      rating:    (json['rating'] ?? 5.0).toDouble(),
      totalRides: json['total_rides'] ?? json['totalRides'] ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : json['createdAt'] != null
              ? DateTime.parse(json['createdAt'])
              : DateTime.now(),
      isVerified: json['is_active'] ?? json['isVerified'] ?? json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id':           id,
      'first_name':   firstName,
      'last_name':    lastName,
      'email':        email,
      'phone':        phone,
      'role':         role,
      'profile_image': profileImage,
      'rating':       rating,
      'total_rides':  totalRides,
      'created_at':   createdAt.toIso8601String(),
      'is_active':    isVerified,
    };
  }
}
