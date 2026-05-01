import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../config/app_mode.dart';
import '../../config/theme.dart';
import '../../services/mock_data.dart';
import '../../widgets/decor.dart';
import '../chat/chat_screen.dart';
import '../chat/new_chat_sheet.dart';

class ChatsListScreen extends StatelessWidget {
  const ChatsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final chats =
        AppModeConfig.isPreview ? MockData.recentChats() : <RecentChat>[];
    final unread = chats.fold<int>(0, (sum, c) => sum + c.unread);

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: BackgroundBlobs()),
          SafeArea(
            child: Column(
              children: [
                PageHeader(
                  title: '메시지',
                  accentText: '✨',
                  subtitle: unread > 0
                      ? '$unread개의 안 읽은 메시지가 있어요'
                      : '모든 메시지를 확인했어요',
                  onBack: () => Navigator.of(context).maybePop(),
                  actions: [
                    HeaderActionButton(
                      icon: Icons.search_rounded,
                      onTap: () {},
                    ),
                  ],
                ),
                Expanded(
                  child: chats.isEmpty
                      ? _Empty(onCompose: () => _openCompose(context))
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                          children: [
                            const _SectionLabel('최근 대화'),
                            const SizedBox(height: 8),
                            ...chats.map((c) => _ChatCard(chat: c)),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: chats.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _openCompose(context),
              backgroundColor: Colors.transparent,
              elevation: 0,
              extendedPadding: EdgeInsets.zero,
              label: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  gradient: AppColors.gradient,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.45),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.edit_rounded,
                        color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text(
                      '새 메시지',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  void _openCompose(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const NewChatSheet(),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: AppColors.textSecondary,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _ChatCard extends StatelessWidget {
  const _ChatCard({required this.chat});
  final RecentChat chat;

  @override
  Widget build(BuildContext context) {
    final p = chat.peer;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => ChatScreen(other: p)),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        gradient: chat.unread > 0 ? AppColors.gradient : null,
                        shape: BoxShape.circle,
                      ),
                      child: ClipOval(
                        child: Container(
                          color: Colors.white,
                          padding: const EdgeInsets.all(2),
                          child: ClipOval(
                            child: SizedBox(
                              width: 48,
                              height: 48,
                              child: (p.avatarUrl != null &&
                                      p.avatarUrl!.isNotEmpty)
                                  ? CachedNetworkImage(
                                      imageUrl: p.avatarUrl!,
                                      fit: BoxFit.cover,
                                      errorWidget: (c, u, e) => _Initial(
                                          name: p.displayName ?? '?'),
                                    )
                                  : _Initial(name: p.displayName ?? '?'),
                            ),
                          ),
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
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              p.displayName ?? '친구',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Text(
                            _relative(chat.lastAt),
                            style: TextStyle(
                              fontSize: 11,
                              color: chat.unread > 0
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                              fontWeight: chat.unread > 0
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              chat.lastMessage,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                color: chat.unread > 0
                                    ? AppColors.textPrimary
                                    : AppColors.textSecondary,
                                fontWeight: chat.unread > 0
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          ),
                          if (chat.unread > 0)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                gradient: AppColors.gradient,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '${chat.unread}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
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

class _Empty extends StatelessWidget {
  const _Empty({required this.onCompose});
  final VoidCallback onCompose;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.12),
                    AppColors.accent.withValues(alpha: 0.12),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.forum_rounded,
                  size: 44, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            const Text(
              '아직 대화가 없어요',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            const Text(
              '친구에게 첫 메시지를 보내보세요 💌',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: onCompose,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 22, vertical: 14),
                decoration: BoxDecoration(
                  gradient: AppColors.gradient,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.45),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.edit_rounded,
                        color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text(
                      '새 메시지',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
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
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
