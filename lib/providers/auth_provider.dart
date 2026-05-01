import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../config/app_mode.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/mock_data.dart';
import '../services/profile_service.dart';

enum AuthStage { unknown, signedOut, needsProfile, signedIn }

class AuthProvider extends ChangeNotifier {
  AuthProvider({AuthService? auth, ProfileService? profile})
      : _auth = auth ?? AuthService(),
        _profile = profile ?? ProfileService() {
    _init();
  }

  final AuthService _auth;
  final ProfileService _profile;
  StreamSubscription<sb.AuthState>? _sub;

  AuthStage stage = AuthStage.unknown;
  UserProfile? profile;
  String? pendingPhone;

  Future<void> _init() async {
    if (AppModeConfig.isPreview) {
      // UI 미리보기: 가짜 로그인 상태로 바로 진입
      profile = MockData.me;
      stage = AuthStage.signedIn;
      notifyListeners();
      return;
    }

    final user = _auth.currentUser;
    if (user == null) {
      stage = AuthStage.signedOut;
      notifyListeners();
    } else {
      await _loadProfile(user.id);
    }
    _sub = _auth.authStateChanges.listen((event) async {
      final u = event.session?.user;
      if (u == null) {
        stage = AuthStage.signedOut;
        profile = null;
      } else {
        await _loadProfile(u.id);
      }
      notifyListeners();
    });
  }

  Future<void> _loadProfile(String userId) async {
    try {
      final p = await _profile.fetchProfile(userId);
      profile = p;
      stage = (p == null || p.displayName == null || p.displayName!.isEmpty)
          ? AuthStage.needsProfile
          : AuthStage.signedIn;
    } catch (_) {
      stage = AuthStage.needsProfile;
    }
    notifyListeners();
  }

  Future<void> sendOtp(String phoneE164) async {
    pendingPhone = phoneE164;
    if (AppModeConfig.isPreview) {
      // 미리보기: 실제 전송 없이 다음 화면으로
      notifyListeners();
      return;
    }
    await _auth.sendOtp(phoneE164);
    notifyListeners();
  }

  Future<void> verifyOtp(String token) async {
    if (AppModeConfig.isPreview) {
      profile = MockData.me;
      stage = AuthStage.signedIn;
      notifyListeners();
      return;
    }
    final phone = pendingPhone;
    if (phone == null) throw StateError('phone not set');
    await _auth.verifyOtp(phoneE164: phone, token: token);
  }

  Future<void> saveProfile({
    required String displayName,
    String? avatarUrl,
    String? statusMessage,
  }) async {
    if (AppModeConfig.isPreview) {
      profile = (profile ?? MockData.me).copyWith(
        displayName: displayName,
        avatarUrl: avatarUrl,
        statusMessage: statusMessage,
      );
      stage = AuthStage.signedIn;
      notifyListeners();
      return;
    }
    final user = _auth.currentUser;
    if (user == null) return;
    final updated = await _profile.upsertProfile(
      UserProfile(
        id: user.id,
        phone: user.phone,
        displayName: displayName,
        avatarUrl: avatarUrl,
        statusMessage: statusMessage,
      ),
    );
    profile = updated;
    stage = AuthStage.signedIn;
    notifyListeners();
  }

  Future<void> updateStatus(String status) async {
    if (profile == null) return;
    final updated = profile!.copyWith(statusMessage: status);
    if (AppModeConfig.isPreview) {
      profile = updated;
      notifyListeners();
      return;
    }
    profile = await _profile.upsertProfile(updated);
    notifyListeners();
  }

  Future<void> signOut() async {
    if (AppModeConfig.isPreview) {
      stage = AuthStage.signedOut;
      profile = null;
      notifyListeners();
      return;
    }
    await _auth.signOut();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
