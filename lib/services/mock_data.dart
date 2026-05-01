import 'package:latlong2/latlong.dart';

import '../models/friend_location.dart';
import '../models/message.dart';
import '../models/user_profile.dart';

class RecentChat {
  const RecentChat({
    required this.peer,
    required this.lastMessage,
    required this.lastAt,
    required this.unread,
  });

  final UserProfile peer;
  final String lastMessage;
  final DateTime lastAt;
  final int unread;
}

/// 전화번호부에서 매칭된 추천 친구
class ContactSuggestion {
  const ContactSuggestion({
    required this.profile,
    required this.contactName,
    required this.mutuals,
  });

  /// 앱 가입자 프로필
  final UserProfile profile;

  /// 내 전화번호부에 저장된 이름 (앱 닉네임과 다를 수 있음)
  final String contactName;
  final int mutuals;
}

class MockData {
  static const meId = 'me-uuid';

  static final me = UserProfile(
    id: meId,
    phone: '+82 10-1234-5678',
    displayName: '나',
    avatarUrl: null,
    statusMessage: '오늘도 화이팅 ✨',
    updatedAt: DateTime.now(),
  );

  /// 서울 시청 근처
  static const myLocation = LatLng(37.5665, 126.9780);

  // ─────────────────────────────────────
  // 프로필 풀
  // ─────────────────────────────────────

  static const _jisoo = UserProfile(
    id: 'jisoo-uuid',
    phone: '+82 10-2222-3333',
    displayName: '지수',
    avatarUrl:
        'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200&h=200&fit=crop',
    statusMessage: '카페에서 작업중 ☕️',
  );

  static const _minho = UserProfile(
    id: 'minho-uuid',
    phone: '+82 10-3333-4444',
    displayName: '민호',
    avatarUrl:
        'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=200&h=200&fit=crop',
    statusMessage: '점심 뭐 먹지 🍜',
  );

  static const _soyeon = UserProfile(
    id: 'soyeon-uuid',
    phone: '+82 10-4444-5555',
    displayName: '소연',
    avatarUrl:
        'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=200&h=200&fit=crop',
    statusMessage: '한강 산책중 🌳',
  );

  static const _jaehyun = UserProfile(
    id: 'jaehyun-uuid',
    phone: '+82 10-5555-6666',
    displayName: '재현',
    avatarUrl:
        'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200&h=200&fit=crop',
    statusMessage: '운동 끝 💪',
  );

  static const _haneul = UserProfile(
    id: 'haneul-uuid',
    phone: '+82 10-6666-7777',
    displayName: '하늘',
    avatarUrl:
        'https://images.unsplash.com/photo-1502823403499-6ccfcf4fb453?w=200&h=200&fit=crop',
    statusMessage: '여행 중 ✈️',
  );

  static const _doyoon = UserProfile(
    id: 'doyoon-uuid',
    phone: '+82 10-7777-8888',
    displayName: '도윤',
    avatarUrl:
        'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200&h=200&fit=crop',
    statusMessage: '책 읽는 중 📚',
  );

  static const _chaerin = UserProfile(
    id: 'chaerin-uuid',
    phone: '+82 10-8888-9999',
    displayName: '채린',
    avatarUrl:
        'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200&h=200&fit=crop',
    statusMessage: '오늘 약속 있어요',
  );

  // ─────────────────────────────────────
  // 친구 상태 (수락된 친구 / 받은 요청 / 보낸 요청)
  // ─────────────────────────────────────

  /// 수락된 친구 (지도에 마커로 표시)
  static List<FriendLocation> acceptedFriends() {
    final now = DateTime.now();
    return [
      FriendLocation(
        profile: _jisoo,
        lat: 37.5685,
        lng: 126.9810,
        updatedAt: now.subtract(const Duration(minutes: 3)),
      ),
      FriendLocation(
        profile: _minho,
        lat: 37.5650,
        lng: 126.9740,
        updatedAt: now.subtract(const Duration(minutes: 12)),
      ),
    ];
  }

  /// 나에게 친구 요청을 보낸 사람들 (수락/거절 가능)
  static List<UserProfile> incomingRequests() => const [_soyeon];

  /// 내가 보낸 친구 요청 (수락 대기중)
  static List<UserProfile> outgoingRequests() => const [_jaehyun];

  /// 전화번호부 매칭으로 추천된 사람들
  static List<ContactSuggestion> contactSuggestions() => const [
        ContactSuggestion(
          profile: _haneul,
          contactName: '하늘 (대학동기)',
          mutuals: 4,
        ),
        ContactSuggestion(
          profile: _doyoon,
          contactName: '도윤이형',
          mutuals: 2,
        ),
        ContactSuggestion(
          profile: _chaerin,
          contactName: '김채린',
          mutuals: 1,
        ),
      ];

  // ─────────────────────────────────────
  // 채팅 (수락된 친구만 가능)
  // ─────────────────────────────────────

  static List<RecentChat> recentChats() {
    return [
      RecentChat(
        peer: _jisoo,
        lastMessage: '오 가까이 있네! 커피 한잔?',
        lastAt: DateTime.now().subtract(const Duration(minutes: 4)),
        unread: 2,
      ),
      RecentChat(
        peer: _minho,
        lastMessage: '점심 같이 먹을래?',
        lastAt: DateTime.now().subtract(const Duration(hours: 1)),
        unread: 0,
      ),
    ];
  }

  static List<ChatMessage> conversationWith(String otherId) {
    final base = DateTime.now().subtract(const Duration(minutes: 30));
    return [
      ChatMessage(
        id: 'm1',
        senderId: otherId,
        receiverId: meId,
        content: '안녕! 어디야?',
        createdAt: base,
      ),
      ChatMessage(
        id: 'm2',
        senderId: meId,
        receiverId: otherId,
        content: '시청 근처야 ㅎㅎ',
        createdAt: base.add(const Duration(minutes: 1)),
      ),
      ChatMessage(
        id: 'm3',
        senderId: otherId,
        receiverId: meId,
        content: '오 가까이 있네! 커피 한잔?',
        createdAt: base.add(const Duration(minutes: 2)),
      ),
    ];
  }

  // ─────────────────────────────────────
  // 홈 피드용 추가 데이터
  // ─────────────────────────────────────

  static String greeting() {
    final h = DateTime.now().hour;
    if (h < 6) return '늦은 밤이에요 🌙';
    if (h < 12) return '좋은 아침이에요 ☀️';
    if (h < 18) return '좋은 오후예요 🌤️';
    return '편안한 저녁이에요 🌆';
  }
}
