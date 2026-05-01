import 'user_profile.dart';

class FriendLocation {
  final UserProfile profile;
  final double lat;
  final double lng;
  final DateTime updatedAt;

  const FriendLocation({
    required this.profile,
    required this.lat,
    required this.lng,
    required this.updatedAt,
  });

  factory FriendLocation.fromJson(Map<String, dynamic> json) {
    final profile =
        UserProfile.fromJson(json['profiles'] as Map<String, dynamic>);
    return FriendLocation(
      profile: profile,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      updatedAt:
          DateTime.tryParse(json['updated_at'] as String? ?? '') ??
              DateTime.now(),
    );
  }
}
