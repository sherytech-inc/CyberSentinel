class AnalystProfile {
  final String userId;
  final String email;
  final String role;
  final String displayName;
  final bool isActive;

  AnalystProfile({
    required this.userId,
    required this.email,
    required this.role,
    required this.displayName,
    required this.isActive,
  });

  factory AnalystProfile.fromJson(Map<String, dynamic> json) {
    return AnalystProfile(
      userId: json['user_id'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'analyst',
      displayName: json['display_name'] ?? '',
      isActive: json['is_active'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'email': email,
      'role': role,
      'display_name': displayName,
      'is_active': isActive,
    };
  }
}
