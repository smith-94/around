class UserProfile {
  final String id;
  final String? phone;
  final String? displayName;
  final String? avatarUrl;
  final String? statusMessage;
  final DateTime? updatedAt;

  const UserProfile({
    required this.id,
    this.phone,
    this.displayName,
    this.avatarUrl,
    this.statusMessage,
    this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'] as String,
        phone: json['phone'] as String?,
        displayName: json['display_name'] as String?,
        avatarUrl: json['avatar_url'] as String?,
        statusMessage: json['status_message'] as String?,
        updatedAt: json['updated_at'] != null
            ? DateTime.tryParse(json['updated_at'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'phone': phone,
        'display_name': displayName,
        'avatar_url': avatarUrl,
        'status_message': statusMessage,
      };

  UserProfile copyWith({
    String? displayName,
    String? avatarUrl,
    String? statusMessage,
  }) =>
      UserProfile(
        id: id,
        phone: phone,
        displayName: displayName ?? this.displayName,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        statusMessage: statusMessage ?? this.statusMessage,
        updatedAt: updatedAt,
      );
}
