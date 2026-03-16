class UserModel {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String role; // 'passenger' | 'rider' | 'admin'
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

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? json['id'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      role: json['role'] ?? 'passenger',
      profileImage: json['profileImage'],
      rating: (json['rating'] ?? 5.0).toDouble(),
      totalRides: json['totalRides'] ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      isVerified: json['isVerified'] ?? json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'role': role,
      'profileImage': profileImage,
      'rating': rating,
      'totalRides': totalRides,
      'createdAt': createdAt.toIso8601String(),
      'isVerified': isVerified,
    };
  }
}
