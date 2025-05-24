class AuthResponse {
  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final UserProfile? user;

  AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['access'],
      refreshToken: json['refresh'],
      tokenType: json['token_type'] ?? 'Bearer',
      user: json['user'] != null ? UserProfile.fromJson(json['user']) : null,
    );
  }
}

class UserProfile {
  final int id;
  final String username;
  final String email;
  final String? phone;
  final int? district;
  final String? profilePicture;
  final String? bio;
  final bool isActive;
  final bool isStaff;
  final bool isSuperuser;
  final bool isVerified;
  final bool isApproved;
  final bool isBlocked;
  final bool isDeleted;

  UserProfile({
    required this.id,
    required this.username,
    required this.email,
    this.phone,
    this.district,
    this.profilePicture,
    this.bio,
    required this.isActive,
    required this.isStaff,
    required this.isSuperuser,
    required this.isVerified,
    required this.isApproved,
    required this.isBlocked,
    required this.isDeleted,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      phone: json['phone'],
      district: json['district'],
      profilePicture: json['profile_picture'],
      bio: json['bio'],
      isActive: json['is_active'] ?? false,
      isStaff: json['is_staff'] ?? false,
      isSuperuser: json['is_superuser'] ?? false,
      isVerified: json['is_verified'] ?? false,
      isApproved: json['is_approved'] ?? false,
      isBlocked: json['is_blocked'] ?? false,
      isDeleted: json['is_deleted'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'phone': phone,
      'district': district,
      'profile_picture': profilePicture,
      'bio': bio,
      'is_active': isActive,
      'is_staff': isStaff,
      'is_superuser': isSuperuser,
      'is_verified': isVerified,
      'is_approved': isApproved,
      'is_blocked': isBlocked,
      'is_deleted': isDeleted,
    };
  }
} 