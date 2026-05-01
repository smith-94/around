import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../models/friend_location.dart';
import '../../models/user_profile.dart';
import '../../providers/friends_provider.dart';
import '../../services/mock_data.dart';
import '../../widgets/decor.dart';
import '../chat/chat_screen.dart';
import 'my_qr_sheet.dart';

class FriendsListScreen extends StatefulWidget {
  const FriendsListScreen({super.key});

  @override
  State<FriendsListScreen> createState() => _FriendsListScreenState();
}

class _FriendsListScreenState extends State<FriendsListScreen> {
  int _section = 0;

  @override
  Widget build(BuildContext context) {
    final fp = context.watch<FriendsProvider>();
    final tabs = [
      _Tab(label: '친구', count: fp.accepted.length),
      _Tab(label: '받은 요청', count: fp.incoming.length, accent: fp.incoming.isNotEmpty),
      _Tab(label: '보낸 요청', count: fp.outgoing.length),
      _Tab(label: '추천', count: fp.suggestions.length),
    ];

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: BackgroundBlobs()),
          SafeArea(
            child: Column(
              children: [
                PageHeader(
                  title: '친구',
                  accentText: '·',
                  subtitle: '${fp.accepted.length}명의 친구 · '
                      '${fp.incoming.length}개의 받은 요청',
                  actions: [
                    HeaderActionButton(
                      icon: Icons.qr_code_rounded,
                      onTap: () => MyQrSheet.show(context),
                    ),
                    HeaderActionButton(
                      icon: Icons.person_add_alt_1_rounded,
                      primary: true,
                      onTap: () => setState(() => _section = 3),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _SearchBar(),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 38,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: List.generate(tabs.length, (i) {
                      final t = tabs[i];
                      final active = _section == i;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _SegChip(
                          label: t.label,
                          count: t.count,
                          active: active,
                          accent: t.accent,
                          onTap: () => setState(() => _section = i),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: switch (_section) {
                    0 => _AcceptedList(friends: fp.accepted),
                    1 => _IncomingList(
                        requests: fp.incoming,
                        onAccept: fp.acceptRequest,
                        onReject: fp.rejectRequest,
                      ),
                    2 => _OutgoingList(
                        requests: fp.outgoing,
                        onCancel: fp.cancelRequest,
                      ),
                    _ => _SuggestionsList(
                        suggestions: fp.suggestions,
                        onAdd: fp.sendRequest,
                      ),
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Tab {
  const _Tab({required this.label, required this.count, this.accent = false});
  final String label;
  final int count;
  final bool accent;
}

class _SearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Row(
        children: [
          Icon(Icons.search_rounded, color: AppColors.textSecondary),
          SizedBox(width: 10),
          Text(
            '이름 또는 전화번호로 찾기',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _SegChip extends StatelessWidget {
  const _SegChip({
    required this.label,
    required this.count,
    required this.active,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool active;
  final bool accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: active ? AppColors.gradient : null,
          color: active ? null : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: active ? Colors.transparent : AppColors.border,
          ),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: active ? Colors.white : AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: active
                      ? Colors.white.withValues(alpha: 0.25)
                      : (accent
                          ? AppColors.accent.withValues(alpha: 0.15)
                          : AppColors.primary.withValues(alpha: 0.1)),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: active
                        ? Colors.white
                        : (accent ? AppColors.accent : AppColors.primary),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// 섹션별 리스트
// ─────────────────────────────────────────────────────────

class _AcceptedList extends StatelessWidget {
  const _AcceptedList({required this.friends});
  final List<FriendLocation> friends;

  @override
  Widget build(BuildContext context) {
    if (friends.isEmpty) {
      return const _Empty(
        icon: Icons.group_outlined,
        title: '친구가 아직 없어요',
        description: '추천 탭에서 전화번호부 친구를 찾아보세요',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
      itemCount: friends.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final f = friends[i];
        return _FriendRow(
          peer: f.profile,
          subtitle: f.profile.statusMessage ?? '',
          trailing: _IconBtn(
            icon: Icons.chat_bubble_rounded,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ChatScreen(other: f.profile),
              ),
            ),
          ),
          showOnline: true,
        );
      },
    );
  }
}

class _IncomingList extends StatelessWidget {
  const _IncomingList({
    required this.requests,
    required this.onAccept,
    required this.onReject,
  });

  final List<UserProfile> requests;
  final Future<void> Function(UserProfile) onAccept;
  final Future<void> Function(UserProfile) onReject;

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) {
      return const _Empty(
        icon: Icons.inbox_outlined,
        title: '받은 요청이 없어요',
        description: '새 친구 요청이 오면 여기에 표시돼요',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
      itemCount: requests.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final p = requests[i];
        return _FriendRow(
          peer: p,
          subtitle: '친구 요청을 보냈어요',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _IconBtn(
                icon: Icons.close_rounded,
                onTap: () => onReject(p),
                soft: true,
              ),
              const SizedBox(width: 6),
              _IconBtn(
                icon: Icons.check_rounded,
                onTap: () => onAccept(p),
                primary: true,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OutgoingList extends StatelessWidget {
  const _OutgoingList({
    required this.requests,
    required this.onCancel,
  });

  final List<UserProfile> requests;
  final Future<void> Function(UserProfile) onCancel;

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) {
      return const _Empty(
        icon: Icons.outbox_outlined,
        title: '보낸 요청이 없어요',
        description: '추천에서 친구 요청을 보내보세요',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
      itemCount: requests.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final p = requests[i];
        return _FriendRow(
          peer: p,
          subtitle: '수락 대기중',
          trailing: GestureDetector(
            onTap: () => onCancel(p),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: const Text(
                '취소',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SuggestionsList extends StatelessWidget {
  const _SuggestionsList({
    required this.suggestions,
    required this.onAdd,
  });

  final List<ContactSuggestion> suggestions;
  final Future<void> Function(UserProfile) onAdd;

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) {
      return const _Empty(
        icon: Icons.contacts_outlined,
        title: '추천할 친구가 없어요',
        description: '주소록에 새 번호가 추가되면 여기서 알려드릴게요',
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Icon(Icons.contacts_rounded,
                  color: AppColors.primary, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '전화번호부에서 ${suggestions.length}명의 around 친구를 찾았어요',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        ...suggestions.map(
          (s) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _FriendRow(
              peer: s.profile,
              subtitle:
                  '${s.contactName} · 함께 아는 친구 ${s.mutuals}명',
              trailing: GestureDetector(
                onTap: () => onAdd(s.profile),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 9),
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
                  child: const Text(
                    '추가',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────
// 공용 위젯
// ─────────────────────────────────────────────────────────

class _FriendRow extends StatelessWidget {
  const _FriendRow({
    required this.peer,
    required this.subtitle,
    required this.trailing,
    this.showOnline = false,
  });

  final UserProfile peer;
  final String subtitle;
  final Widget trailing;
  final bool showOnline;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            children: [
              ClipOval(
                child: SizedBox(
                  width: 50,
                  height: 50,
                  child: (peer.avatarUrl != null &&
                          peer.avatarUrl!.isNotEmpty)
                      ? CachedNetworkImage(
                          imageUrl: peer.avatarUrl!,
                          fit: BoxFit.cover,
                          errorWidget: (c, u, e) =>
                              _Initial(name: peer.displayName ?? '?'),
                        )
                      : _Initial(name: peer.displayName ?? '?'),
                ),
              ),
              if (showOnline)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 13,
                    height: 13,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2.5),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  peer.displayName ?? '친구',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({
    required this.icon,
    required this.onTap,
    this.primary = false,
    this.soft = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool primary;
  final bool soft;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          gradient: primary ? AppColors.gradient : null,
          color: primary
              ? null
              : (soft ? Colors.white : AppColors.primary.withValues(alpha: 0.1)),
          borderRadius: BorderRadius.circular(11),
          border: soft ? Border.all(color: AppColors.border) : null,
          boxShadow: primary
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Icon(
          icon,
          size: 18,
          color: primary
              ? Colors.white
              : (soft ? AppColors.textSecondary : AppColors.primary),
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
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
