import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';

class AuthService {
  SupabaseClient get _client => SupabaseService.client;

  User? get currentUser => _client.auth.currentUser;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<void> sendOtp(String phoneE164) async {
    await _client.auth.signInWithOtp(phone: phoneE164);
  }

  Future<AuthResponse> verifyOtp({
    required String phoneE164,
    required String token,
  }) {
    return _client.auth.verifyOTP(
      phone: phoneE164,
      token: token,
      type: OtpType.sms,
    );
  }

  Future<void> signOut() => _client.auth.signOut();
}
