import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _statusCtrl = TextEditingController();
  bool _statusEdited = false;

  @override
  void dispose() {
    _statusCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final settings = context.watch<SettingsProvider>();
    final p = auth.profile;

    if (p != null && !_statusEdited && _statusCtrl.text != (p.statusMessage ?? '')) {
      _statusCtrl.text = p.statusMessage ?? '';
    }

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 120),
        children: [
          _Header(
            displayName: p?.displayName ?? '나',
            avatarUrl: p?.avatarUrl,
            phone: p?.phone,
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _Label('상태 메시지'),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _statusCtrl,
                    maxLength: 40,
                    onChanged: (_) => setState(() => _statusEdited = true),
                    onSubmitted: (v) async {
                      await context.read<AuthProvider>().updateStatus(v);
                      setState(() => _statusEdited = false);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('상태가 업데이트됐어요')),
                        );
                      }
                    },
                    decoration: const InputDecoration(
                      hintText: '오늘 기분이나 위치를 알려보세요',
                      counterText: '',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _StatsRow(),

                // ── 위치 / 프라이버시 토글 카드
                const SizedBox(height: 28),
                const _Label('위치 / 프라이버시'),
                const SizedBox(height: 8),
                _ToggleGroup(
                  children: [
                    _ToggleTile(
                      icon: Icons.share_location_rounded,
                      title: '내 위치 공유',
                      description: settings.shareLocation
                          ? '친구들이 지도에서 내 위치를 볼 수 있어요'
                          : '꺼져있어요. 친구들에게 위치가 보이지 않아요',
                      value: settings.shareLocation,
                      onChanged: settings.toggleShareLocation,
                    ),
                    _ToggleTile(
                      icon: Icons.chat_rounded,
                      title: '상태 메시지 표시',
                      description: '마커와 친구 목록에 노출돼요',
                      value: settings.showStatus,
                      onChanged: settings.toggleShowStatus,
                    ),
                    _ToggleTile(
                      icon: Icons.contacts_rounded,
                      title: '전화번호로 검색 허용',
                      description: '내 번호를 아는 사람이 추천 친구로 나를 찾을 수 있어요',
                      value: settings.discoverable,
                      onChanged: settings.toggleDiscoverable,
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                const _Label('알림 / 테마'),
                const SizedBox(height: 8),
                _ToggleGroup(
                  children: [
                    _ToggleTile(
                      icon: Icons.notifications_rounded,
                      title: '푸시 알림',
                      description: '새 메시지와 친구 요청을 알림으로 받아요',
                      value: settings.pushNotifications,
                      onChanged: settings.togglePushNotifications,
                    ),
                    _ToggleTile(
                      icon: Icons.dark_mode_rounded,
                      title: '다크 모드',
                      description: '곧 지원될 예정이에요',
                      value: settings.darkMode,
                      onChanged: settings.toggleDarkMode,
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                const _Label('지원'),
                const SizedBox(height: 8),
                _Tile(
                  icon: Icons.help_outline_rounded,
                  title: '도움말',
                  onTap: () {},
                ),
                _Tile(
                  icon: Icons.info_outline_rounded,
                  title: '약관 및 버전',
                  trailing: const Text('1.0.0',
                      style: TextStyle(color: AppColors.textSecondary)),
                  onTap: () {},
                ),
                const SizedBox(height: 16),
                _Tile(
                  icon: Icons.logout_rounded,
                  title: '로그아웃',
                  iconColor: AppColors.danger,
                  titleColor: AppColors.danger,
                  onTap: () => auth.signOut(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// 헤더 / 통계
// ─────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({
    required this.displayName,
    required this.avatarUrl,
    required this.phone,
  });

  final String displayName;
  final String? avatarUrl;
  final String? phone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, MediaQuery.of(context).padding.top + 20, 20, 28),
      decoration: const BoxDecoration(
        gradient: AppColors.gradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Text(
                '내 정보',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.settings_rounded,
                    color: Colors.white, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.7), width: 3),
                ),
                child: CircleAvatar(
                  radius: 48,
                  backgroundColor: Colors.white.withValues(alpha: 0.25),
                  backgroundImage:
                      (avatarUrl != null && avatarUrl!.isNotEmpty)
                          ? NetworkImage(avatarUrl!)
                          : null,
                  child: (avatarUrl == null || avatarUrl!.isEmpty)
                      ? Text(
                          displayName.characters.first,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                          ),
                        )
                      : null,
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt_rounded,
                      color: AppColors.primary, size: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            displayName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            phone ?? '',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
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
      child: const Row(
        children: [
          Expanded(child: _Stat(value: '2', label: '친구')),
          _Divider(),
          Expanded(child: _Stat(value: '12', label: '대화')),
          _Divider(),
          Expanded(child: _Stat(value: '2.4km', label: '오늘 이동')),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 32, color: AppColors.border);
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────
// 토글 / 라벨 / 타일
// ─────────────────────────────────────────────────────────

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
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

class _ToggleGroup extends StatelessWidget {
  const _ToggleGroup({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      items.add(children[i]);
      if (i < children.length - 1) {
        items.add(const Divider(height: 1, color: AppColors.border));
      }
    }
    return Container(
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
      child: Column(children: items),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  const _ToggleTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: value ? AppColors.gradient : null,
              color: value ? null : AppColors.border.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 20,
              color: value ? Colors.white : AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.title,
    this.trailing,
    this.onTap,
    this.iconColor,
    this.titleColor,
  });

  final IconData icon;
  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: (iconColor ?? AppColors.primary)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon,
                      size: 18, color: iconColor ?? AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: titleColor ?? AppColors.textPrimary,
                    ),
                  ),
                ),
                ?trailing,
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
