import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../models/friend_location.dart';
import '../../models/user_profile.dart';
import '../../providers/auth_provider.dart';
import '../../providers/friends_provider.dart';
import '../../providers/location_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/mock_data.dart';
import '../../widgets/profile_marker.dart';
import '../chat/chat_screen.dart';
import 'chats_list_screen.dart';
import 'friend_preview_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _sheetController = DraggableScrollableController();
  NaverMapController? _naver;
  bool _bootstrapped = false;
  String _markerStateKey = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bootstrapped) return;
    _bootstrapped = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final me = context.read<AuthProvider>().profile?.id;
      if (me != null) {
        context.read<LocationProvider>().bootstrap(me);
        context.read<FriendsProvider>().load(me);
      }
    });
  }

  @override
  void dispose() {
    _sheetController.dispose();
    super.dispose();
  }

  Future<void> _recenter(NLatLng pos) async {
    if (_naver == null) return;
    await _naver!.updateCamera(
      NCameraUpdate.scrollAndZoomTo(target: pos, zoom: 16),
    );
  }

  void _openFriend(FriendLocation friend) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => FriendPreviewSheet(
        friend: friend,
        onMessage: () {
          Navigator.of(context).pop();
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ChatScreen(other: friend.profile),
            ),
          );
        },
      ),
    );
  }

  void _openChats() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ChatsListScreen()),
    );
  }

  void _cycleSheet(List<double> snaps) {
    if (!_sheetController.isAttached) return;
    final cur = _sheetController.size;
    var idx = 0;
    var bestDiff = double.infinity;
    for (var i = 0; i < snaps.length; i++) {
      final d = (snaps[i] - cur).abs();
      if (d < bestDiff) {
        bestDiff = d;
        idx = i;
      }
    }
    final next = snaps[(idx + 1) % snaps.length];
    _sheetController.animateTo(
      next,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  /// 친구/내 위치/설정 변화 시 마커를 새로 그림.
  /// flutter_naver_map 마커는 비트맵 이미지라 위젯 → 비트맵 변환 후 등록.
  Future<void> _refreshMarkers({
    required UserProfile? me,
    required ({double lat, double lng})? myPos,
    required bool shareLocation,
    required bool showStatus,
    required List<FriendLocation> friends,
  }) async {
    if (_naver == null) return;
    final ctx = context;
    if (!ctx.mounted) return;

    final stateKey = [
      if (shareLocation && myPos != null)
        'me:${myPos.lat.toStringAsFixed(5)},${myPos.lng.toStringAsFixed(5)},${me?.statusMessage ?? ''},${me?.avatarUrl ?? ''}',
      ...friends.map((f) =>
          '${f.profile.id}:${f.lat.toStringAsFixed(5)},${f.lng.toStringAsFixed(5)},${f.profile.statusMessage ?? ''}'),
    ].join('|');
    if (stateKey == _markerStateKey) return;
    _markerStateKey = stateKey;

    await _naver!.clearOverlays(type: NOverlayType.marker);

    // 내 마커
    if (shareLocation && myPos != null && me != null) {
      if (!ctx.mounted) return;
      final icon = await NOverlayImage.fromWidget(
        widget: ProfileMarker(
          name: me.displayName ?? '나',
          avatarUrl: me.avatarUrl,
          statusMessage: showStatus ? me.statusMessage : null,
          isMe: true,
        ),
        size: const Size(180, 130),
        context: ctx,
      );
      final marker = NMarker(
        id: 'me',
        position: NLatLng(myPos.lat, myPos.lng),
        icon: icon,
        anchor: const NPoint(0.5, 1.0),
      );
      await _naver!.addOverlay(marker);
    }

    // 친구 마커
    for (final f in friends) {
      if (!ctx.mounted) return;
      final icon = await NOverlayImage.fromWidget(
        widget: ProfileMarker(
          name: f.profile.displayName ?? '친구',
          avatarUrl: f.profile.avatarUrl,
          statusMessage: f.profile.statusMessage,
        ),
        size: const Size(180, 130),
        context: ctx,
      );
      final marker = NMarker(
        id: f.profile.id,
        position: NLatLng(f.lat, f.lng),
        icon: icon,
        anchor: const NPoint(0.5, 1.0),
      );
      marker.setOnTapListener((overlay) {
        _openFriend(f);
        return true;
      });
      await _naver!.addOverlay(marker);
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = context.watch<AuthProvider>().profile;
    final myPosLatLng = context.watch<LocationProvider>().current;
    final settings = context.watch<SettingsProvider>();
    final friendsProv = context.watch<FriendsProvider>();
    final mappedFriends = friendsProv.mappedAccepted;

    final myPos = myPosLatLng == null
        ? null
        : (lat: myPosLatLng.latitude, lng: myPosLatLng.longitude);

    final centerLatLng = myPos != null
        ? NLatLng(myPos.lat, myPos.lng)
        : const NLatLng(37.5665, 126.9780);

    final screenH = MediaQuery.sizeOf(context).height;
    final minSheet = 220.0 / screenH;
    const midSheet = 0.55;
    const maxSheet = 0.92;

    // 데이터가 변경되면 다음 프레임에 마커 갱신
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _refreshMarkers(
        me: me,
        myPos: myPos,
        shareLocation: settings.shareLocation,
        showStatus: settings.showStatus,
        friends: mappedFriends,
      );
    });

    return Scaffold(
      body: Stack(
        children: [
          NaverMap(
            options: NaverMapViewOptions(
              initialCameraPosition: NCameraPosition(
                target: centerLatLng,
                zoom: 15,
              ),
              mapType: NMapType.basic,
              indoorEnable: false,
              locationButtonEnable: false,
              consumeSymbolTapEvents: false,
              minZoom: 4,
              maxZoom: 19,
            ),
            onMapReady: (controller) {
              _naver = controller;
              _refreshMarkers(
                me: me,
                myPos: myPos,
                shareLocation: settings.shareLocation,
                showStatus: settings.showStatus,
                friends: mappedFriends,
              );
            },
          ),

          _TopOverlay(unread: 3, onMessages: _openChats),

          Positioned(
            right: 16,
            bottom: minSheet * screenH + 16,
            child: Column(
              children: [
                _RoundButton(
                  icon: Icons.layers_rounded,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('곧 지도 스타일을 고를 수 있어요')),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _RoundButton(
                  icon: settings.shareLocation
                      ? Icons.my_location_rounded
                      : Icons.location_disabled_rounded,
                  primary: settings.shareLocation,
                  onTap: myPos == null
                      ? null
                      : () => _recenter(NLatLng(myPos.lat, myPos.lng)),
                ),
              ],
            ),
          ),

          DraggableScrollableSheet(
            controller: _sheetController,
            initialChildSize: minSheet,
            minChildSize: minSheet,
            maxChildSize: maxSheet,
            snap: true,
            snapSizes: [minSheet, midSheet, maxSheet],
            builder: (context, scrollCtrl) => _HomeSheet(
              scrollCtrl: scrollCtrl,
              me: me,
              friendsProv: friendsProv,
              onCycle: () => _cycleSheet([minSheet, midSheet, maxSheet]),
              sheetController: _sheetController,
              snapMin: minSheet,
              snapMax: maxSheet,
              onOpenFriend: (p) {
                final loc = friendsProv.accepted
                    .where((f) => f.profile.id == p.id)
                    .firstOrNull;
                if (loc != null && (loc.lat != 0 || loc.lng != 0)) {
                  _recenter(NLatLng(loc.lat, loc.lng));
                  _openFriend(loc);
                } else {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(other: p),
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// 상단 오버레이 (인사 칩 / 알림 / 검색 / 메시지 FAB)
// ─────────────────────────────────────────────────────────

class _TopOverlay extends StatelessWidget {
  const _TopOverlay({required this.unread, required this.onMessages});
  final int unread;
  final VoidCallback onMessages;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        child: Column(
          children: [
            Row(
              children: [
                _Frosted(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '서울 · 시청 근처',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color:
                              AppColors.textPrimary.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                _IconCircle(
                  icon: Icons.notifications_rounded,
                  hasDot: true,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('알림은 곧 추가됩니다')),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(
                        height: 52,
                        padding:
                            const EdgeInsets.symmetric(horizontal: 18),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.88),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.10),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.search_rounded,
                                color: AppColors.textSecondary),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '친구 또는 장소 검색',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            Icon(Icons.tune_rounded,
                                size: 18,
                                color: AppColors.textSecondary),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                _MessageFab(unread: unread, onTap: onMessages),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Frosted extends StatelessWidget {
  const _Frosted({required this.child, required this.padding});
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(999),
            border:
                Border.all(color: Colors.white.withValues(alpha: 0.6)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _IconCircle extends StatelessWidget {
  const _IconCircle({
    required this.icon,
    required this.onTap,
    this.hasDot = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool hasDot;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.10),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, size: 20, color: AppColors.textPrimary),
          ),
          if (hasDot)
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MessageFab extends StatelessWidget {
  const _MessageFab({required this.unread, required this.onTap});
  final int unread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: AppColors.gradient,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.4),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: const SizedBox(
                width: 52,
                height: 52,
                child: Icon(Icons.chat_bubble_rounded,
                    color: Colors.white),
              ),
            ),
          ),
        ),
        if (unread > 0)
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppColors.accent, width: 2),
              ),
              constraints: const BoxConstraints(minWidth: 22),
              alignment: Alignment.center,
              child: Text(
                '$unread',
                style: const TextStyle(
                  color: AppColors.accent,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────
// 홈 시트 (이전 디자인 그대로 — 핸들 탭으로 사이클)
// ─────────────────────────────────────────────────────────

class _HomeSheet extends StatelessWidget {
  const _HomeSheet({
    required this.scrollCtrl,
    required this.me,
    required this.friendsProv,
    required this.onOpenFriend,
    required this.onCycle,
    required this.sheetController,
    required this.snapMin,
    required this.snapMax,
  });

  final ScrollController scrollCtrl;
  final UserProfile? me;
  final FriendsProvider friendsProv;
  final ValueChanged<UserProfile> onOpenFriend;
  final VoidCallback onCycle;
  final DraggableScrollableController sheetController;
  final double snapMin;
  final double snapMax;

  @override
  Widget build(BuildContext context) {
    final accepted = friendsProv.accepted;
    final incoming = friendsProv.incoming;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFFDFBFF),
            AppColors.primary.withValues(alpha: 0.04),
          ],
        ),
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.12),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.10),
            blurRadius: 28,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: ListView(
        controller: scrollCtrl,
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 110),
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onCycle,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: AnimatedBuilder(
                animation: sheetController,
                builder: (context, _) {
                  final atMax = sheetController.isAttached &&
                      (sheetController.size - snapMax).abs() < 0.02;
                  final atMin = sheetController.isAttached &&
                      (sheetController.size - snapMin).abs() < 0.02;
                  return Column(
                    children: [
                      Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 6),
                      AnimatedRotation(
                        turns: atMax ? 0.5 : 0,
                        duration: const Duration(milliseconds: 250),
                        child: Icon(
                          Icons.keyboard_arrow_up_rounded,
                          size: 18,
                          color: atMin
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        MockData.greeting(),
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${me?.displayName ?? '나'}님,\n주변에 ${accepted.length}명의 친구가 있어요',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('🌤️', style: TextStyle(fontSize: 18)),
                      SizedBox(width: 4),
                      Text(
                        '17°',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _SectionHeader(
            title: '주변 친구',
            count: accepted.length,
            actionText: '지도에서 보기',
            onAction: () {},
          ),
          const SizedBox(height: 12),
          if (accepted.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Text(
                '아직 친구가 없어요. 친구를 추가해보세요 ✨',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            )
          else
            SizedBox(
              height: 168,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: accepted.length,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, i) {
                  final f = accepted[i];
                  return _FriendChipCard(
                    friend: f,
                    onTap: () => onOpenFriend(f.profile),
                  );
                },
              ),
            ),
          if (incoming.isNotEmpty) ...[
            const SizedBox(height: 20),
            _SectionHeader(
              title: '받은 친구 요청',
              count: incoming.length,
              accent: true,
            ),
            const SizedBox(height: 12),
            ...incoming.map(
              (p) => Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: _IncomingRequestCard(
                  peer: p,
                  onAccept: () => friendsProv.acceptRequest(p),
                  onReject: () => friendsProv.rejectRequest(p),
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          _SectionHeader(title: '빠른 액션', count: null),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: _QuickAction(
                    icon: Icons.person_add_alt_1_rounded,
                    label: '친구 추가',
                    onTap: () {},
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _QuickAction(
                    icon: Icons.share_location_rounded,
                    label: '위치 공유',
                    onTap: () {},
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _QuickAction(
                    icon: Icons.flag_rounded,
                    label: '약속 만들기',
                    onTap: () {},
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _SectionHeader(title: '오늘의 활동', count: null),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: _ActivityCard(),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.count,
    this.actionText,
    this.onAction,
    this.accent = false,
  });

  final String title;
  final int? count;
  final String? actionText;
  final VoidCallback? onAction;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (count != null) ...[
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                gradient: accent ? AppColors.gradient : null,
                color: accent
                    ? null
                    : AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: accent ? Colors.white : AppColors.primary,
                ),
              ),
            ),
          ],
          const Spacer(),
          if (actionText != null)
            GestureDetector(
              onTap: onAction,
              child: Text(
                actionText!,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FriendChipCard extends StatelessWidget {
  const _FriendChipCard({required this.friend, required this.onTap});
  final FriendLocation friend;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = friend.profile;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipOval(
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: (p.avatarUrl != null && p.avatarUrl!.isNotEmpty)
                        ? CachedNetworkImage(
                            imageUrl: p.avatarUrl!,
                            fit: BoxFit.cover,
                            errorWidget: (c, u, e) =>
                                _Initial(name: p.displayName ?? '?'),
                          )
                        : _Initial(name: p.displayName ?? '?'),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              p.displayName ?? '친구',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              p.statusMessage ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11.5,
                color: AppColors.textSecondary,
                height: 1.3,
              ),
            ),
            const Spacer(),
            Row(
              children: [
                const Icon(Icons.location_on_rounded,
                    size: 12, color: AppColors.primary),
                const SizedBox(width: 3),
                Text(
                  _relative(friend.updatedAt),
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _relative(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return '방금';
    if (d.inMinutes < 60) return '${d.inMinutes}분 전';
    if (d.inHours < 24) return '${d.inHours}시간 전';
    return '${d.inDays}일 전';
  }
}

class _IncomingRequestCard extends StatelessWidget {
  const _IncomingRequestCard({
    required this.peer,
    required this.onAccept,
    required this.onReject,
  });

  final UserProfile peer;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.05),
            AppColors.accent.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          ClipOval(
            child: SizedBox(
              width: 48,
              height: 48,
              child: (peer.avatarUrl != null && peer.avatarUrl!.isNotEmpty)
                  ? CachedNetworkImage(
                      imageUrl: peer.avatarUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (c, u, e) =>
                          _Initial(name: peer.displayName ?? '?'),
                    )
                  : _Initial(name: peer.displayName ?? '?'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  peer.displayName ?? '친구',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Text(
                  '친구 요청을 보냈어요',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onReject,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(Icons.close_rounded,
                  size: 18, color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onAccept,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: AppColors.gradient,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.check_rounded,
                  size: 18, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: AppColors.gradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 18, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.gradient,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '오늘의 만남 🎉',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '지수님과 30분 함께\n반경 200m 이내였어요',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.95),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Text('🚶', style: TextStyle(fontSize: 28)),
          ),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    this.onTap,
    this.primary = false,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: primary ? AppColors.gradient : null,
        color: primary ? null : Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: primary
                ? AppColors.primary.withValues(alpha: 0.4)
                : Colors.black.withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 48,
            height: 48,
            child: Icon(
              icon,
              size: 20,
              color: primary ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _Initial extends StatelessWidget {
  const _Initial({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppColors.gradient),
      child: Center(
        child: Text(
          name.characters.first,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
