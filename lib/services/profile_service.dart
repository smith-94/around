import '../models/user_profile.dart';
import 'supabase_service.dart';

class ProfileService {
  Future<UserProfile?> fetchProfile(String userId) async {
    final row = await SupabaseService.client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    if (row == null) return null;
    return UserProfile.fromJson(row);
  }

  Future<UserProfile> upsertProfile(UserProfile profile) async {
    final row = await SupabaseService.client
        .from('profiles')
        .upsert(profile.toJson())
        .select()
        .single();
    return UserProfile.fromJson(row);
  }
}
