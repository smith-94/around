import 'dart:async';

import '../models/friend_location.dart';
import 'supabase_service.dart';

class FriendsService {
  Future<List<FriendLocation>> fetchFriendLocations(String userId) async {
    // friend ids of current user (accepted)
    final friendships = await SupabaseService.client
        .from('friendships')
        .select('user_id, friend_id, status')
        .eq('status', 'accepted')
        .or('user_id.eq.$userId,friend_id.eq.$userId');

    final ids = <String>{};
    for (final f in friendships as List) {
      final uid = f['user_id'] as String;
      final fid = f['friend_id'] as String;
      ids.add(uid == userId ? fid : uid);
    }
    if (ids.isEmpty) return [];

    final rows = await SupabaseService.client
        .from('locations')
        .select('lat, lng, updated_at, profiles(*)')
        .inFilter('user_id', ids.toList());

    return (rows as List)
        .map((r) => FriendLocation.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  Stream<List<Map<String, dynamic>>> locationStream() {
    return SupabaseService.client
        .from('locations')
        .stream(primaryKey: ['user_id']);
  }
}
