import 'dart:async';

import 'package:flutter/foundation.dart';

import '../config/app_mode.dart';
import '../models/friend_location.dart';
import '../models/user_profile.dart';
import '../services/friends_service.dart';
import '../services/mock_data.dart';

class FriendsProvider extends ChangeNotifier {
  FriendsProvider({FriendsService? service})
      : _service = service ?? FriendsService();

  final FriendsService _service;
  StreamSubscription? _sub;

  /// 수락된 친구 (지도 표시용)
  List<FriendLocation> accepted = [];

  /// 받은 친구 요청 (수락/거절 가능)
  List<UserProfile> incoming = [];

  /// 보낸 친구 요청 (수락 대기)
  List<UserProfile> outgoing = [];

  /// 전화번호부 매칭 추천
  List<ContactSuggestion> suggestions = [];

  bool loading = false;
  String? error;

  Future<void> load(String userId) async {
    if (AppModeConfig.isPreview) {
      accepted = MockData.acceptedFriends();
      incoming = MockData.incomingRequests();
      outgoing = MockData.outgoingRequests();
      suggestions = MockData.contactSuggestions();
      notifyListeners();
      return;
    }

    loading = true;
    error = null;
    notifyListeners();
    try {
      accepted = await _service.fetchFriendLocations(userId);
      // TODO(production): incoming / outgoing / contact 매칭 쿼리 추가
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }

    _sub?.cancel();
    _sub = _service.locationStream().listen((_) {
      _service.fetchFriendLocations(userId).then((list) {
        accepted = list;
        notifyListeners();
      }).catchError((_) {});
    });
  }

  // ─────────────────────────────────────
  // 친구 요청 액션 (preview 에선 로컬 상태만 변경)
  // ─────────────────────────────────────

  Future<void> acceptRequest(UserProfile peer) async {
    incoming = incoming.where((p) => p.id != peer.id).toList();
    accepted = [
      ...accepted,
      FriendLocation(
        profile: peer,
        // 수락된 직후엔 위치 미공개로 둠
        lat: 0,
        lng: 0,
        updatedAt: DateTime.now(),
      ),
    ];
    notifyListeners();
    if (AppModeConfig.isProduction) {
      // TODO: friendships 테이블 status='accepted' 업데이트
    }
  }

  Future<void> rejectRequest(UserProfile peer) async {
    incoming = incoming.where((p) => p.id != peer.id).toList();
    notifyListeners();
  }

  Future<void> cancelRequest(UserProfile peer) async {
    outgoing = outgoing.where((p) => p.id != peer.id).toList();
    notifyListeners();
  }

  Future<void> sendRequest(UserProfile peer) async {
    if (outgoing.any((p) => p.id == peer.id)) return;
    outgoing = [...outgoing, peer];
    suggestions =
        suggestions.where((s) => s.profile.id != peer.id).toList();
    notifyListeners();
  }

  /// 지도에 표시할 (위치가 유효한) 친구만
  List<FriendLocation> get mappedAccepted =>
      accepted.where((f) => f.lat != 0 || f.lng != 0).toList();

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
