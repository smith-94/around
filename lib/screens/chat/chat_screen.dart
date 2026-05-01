import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../models/message.dart';
import '../../models/user_profile.dart';
import '../../providers/auth_provider.dart';
import '../../providers/messages_provider.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.other});
  final UserProfile other;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  late final MessagesProvider _messages;

  @override
  void initState() {
    super.initState();
    _messages = MessagesProvider();
    final me = context.read<AuthProvider>().profile?.id;
    if (me != null) {
      _messages.open(me: me, other: widget.other.id);
    }
  }

  @override
  void dispose() {
    _messages.close();
    _messages.dispose();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _input.text;
    if (text.trim().isEmpty) return;
    _input.clear();
    await _messages.send(text);
    if (_scroll.hasClients) {
      _scroll.animateTo(
        _scroll.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _messages,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: Column(
          children: [
            _ChatAppBar(peer: widget.other),
            Expanded(
              child: Consumer<MessagesProvider>(
                builder: (context, mp, _) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (_scroll.hasClients) {
                      _scroll.jumpTo(_scroll.position.maxScrollExtent);
                    }
                  });
                  if (mp.messages.isEmpty) {
                    return _Empty(peer: widget.other);
                  }
                  return ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: mp.messages.length,
                    itemBuilder: (_, i) {
                      final m = mp.messages[i];
                      final me = context.read<AuthProvider>().profile?.id;
                      final mine = m.senderId == me;
                      final showHead = i == 0 ||
                          mp.messages[i - 1].senderId != m.senderId;
                      return _Bubble(
                        message: m,
                        mine: mine,
                        showAvatar: !mine && showHead,
                        peer: widget.other,
                      );
                    },
                  );
                },
              ),
            ),
            _Composer(controller: _input, onSend: _send),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// 앱바
// ─────────────────────────────────────────────────────────

class _ChatAppBar extends StatelessWidget {
  const _ChatAppBar({required this.peer});
  final UserProfile peer;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: Row(
            children: [
              _AppBarBtn(
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: () => Navigator.of(context).maybePop(),
              ),
              const SizedBox(width: 8),
              Stack(
                children: [
                  ClipOval(
                    child: SizedBox(
                      width: 42,
                      height: 42,
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
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      peer.displayName ?? '친구',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Text(
                          '온라인',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (peer.statusMessage != null &&
                            peer.statusMessage!.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Text(
                            '· ${peer.statusMessage}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              _AppBarBtn(
                icon: Icons.location_on_rounded,
                onTap: () {},
                primary: true,
              ),
              const SizedBox(width: 6),
              _AppBarBtn(
                icon: Icons.more_vert_rounded,
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppBarBtn extends StatelessWidget {
  const _AppBarBtn({
    required this.icon,
    required this.onTap,
    this.primary = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          gradient: primary ? AppColors.gradient : null,
          color: primary ? null : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          size: 18,
          color: primary ? Colors.white : AppColors.textPrimary,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// 메시지 버블
// ─────────────────────────────────────────────────────────

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.message,
    required this.mine,
    required this.showAvatar,
    required this.peer,
  });

  final ChatMessage message;
  final bool mine;
  final bool showAvatar;
  final UserProfile peer;

  @override
  Widget build(BuildContext context) {
    final time = TimeOfDay.fromDateTime(message.createdAt);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment:
            mine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!mine)
            SizedBox(
              width: 32,
              child: showAvatar
                  ? ClipOval(
                      child: SizedBox(
                        width: 28,
                        height: 28,
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
                    )
                  : null,
            ),
          if (!mine) const SizedBox(width: 6),
          if (mine)
            Padding(
              padding: const EdgeInsets.only(right: 6, bottom: 4),
              child: Text(
                _fmtTime(time),
                style: const TextStyle(
                  fontSize: 10.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.72,
              ),
              decoration: BoxDecoration(
                gradient: mine ? AppColors.gradient : null,
                color: mine ? null : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(mine ? 18 : 6),
                  bottomRight: Radius.circular(mine ? 6 : 18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: mine
                        ? AppColors.primary.withValues(alpha: 0.25)
                        : Colors.black.withValues(alpha: 0.05),
                    blurRadius: mine ? 12 : 6,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                message.content,
                style: TextStyle(
                  color: mine ? Colors.white : AppColors.textPrimary,
                  fontSize: 14.5,
                  height: 1.35,
                ),
              ),
            ),
          ),
          if (!mine)
            Padding(
              padding: const EdgeInsets.only(left: 6, bottom: 4),
              child: Text(
                _fmtTime(time),
                style: const TextStyle(
                  fontSize: 10.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  static String _fmtTime(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    final ap = t.period == DayPeriod.am ? '오전' : '오후';
    return '$ap $h:$m';
  }
}

// ─────────────────────────────────────────────────────────
// 입력창
// ─────────────────────────────────────────────────────────

class _Composer extends StatelessWidget {
  const _Composer({required this.controller, required this.onSend});
  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 14,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.add_rounded,
                  color: AppColors.primary),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: TextField(
                  controller: controller,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => onSend(),
                  decoration: const InputDecoration(
                    hintText: '메시지를 입력하세요',
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onSend,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: AppColors.gradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.send_rounded,
                    color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.peer});
  final UserProfile peer;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                gradient: AppColors.gradient,
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: SizedBox(
                  width: 80,
                  height: 80,
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
            ),
            const SizedBox(height: 16),
            Text(
              peer.displayName ?? '친구',
              style:
                  const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            const Text(
              '첫 메시지를 보내보세요 💌',
              style: TextStyle(
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
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
