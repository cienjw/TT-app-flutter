import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/socket_client.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../auth/presentation/login_screen.dart';
import '../data/profile_repository.dart';
import '../domain/profile_provider.dart';
import '../../chat/domain/chat_provider.dart';
import '../../footprints/domain/footprint_provider.dart';
import '../../../shared/widgets/profile_avatar.dart';
import 'blocked_users_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('정말 로그아웃하시겠어요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('로그아웃', style: TextStyle(color: context.cs.error)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // 소켓 끊고 토큰/온보딩 플래그 전부 삭제
    SocketClient.disconnect();
    await SecureStorage.clearAll();

    // 강제 초기화 추가 ✅
    ref.invalidate(myProfileProvider);
    ref.invalidate(myGroupsProvider);
    ref.invalidate(footprintsProvider);

    if (!context.mounted) return;

    // 로그인 화면으로 완전히 초기화 (invalidate 대신 화면 전환으로 처리)
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(myProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('프로필'),
      ),
      body: profileAsync.when(
        data: (profile) => ListView(
          children: [
            _buildProfileHeader(context, profile),
            const SizedBox(height: 12),
            const Divider(height: 1),
            _MenuTile(
              icon: CupertinoIcons.pencil,
              label: '내 정보 수정',
              onTap: () {}, // 추후 구현
            ),
            _MenuTile(
              icon: CupertinoIcons.bell,
              label: '알림 설정',
              onTap: () {},
            ),
            _MenuTile(
              icon: Icons.block_flipped,          // (네 현재 아이콘 그대로)
              label: '차단 관리',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BlockedUsersScreen()),
              ),
            ),
            _MenuTile(
              icon: CupertinoIcons.question_circle,
              label: '이용 가이드',
              onTap: () {},
            ),
            const Divider(height: 1),
            _MenuTile(
              icon: CupertinoIcons.square_arrow_right,
              label: '로그아웃',
              isDestructive: true,
              onTap: () => _logout(context, ref),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text('프로필을 불러오지 못했어요: $e',
                style: AppTextStyles.caption),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, UserProfile profile) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        children: [
          ProfileAvatar(imageId: profile.profileImg, radius: 36),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(profile.nickname, style: AppTextStyles.headline2),
                if (profile.typeLabel != null) ...[
                  const SizedBox(height: 4),
                  Text(profile.typeLabel!,
                      style: AppTextStyles.body.copyWith(
                        color: context.cs.primary,
                        fontWeight: FontWeight.w600,
                      )),
                ],
                if (profile.mbti != null) ...[
                  const SizedBox(height: 2),
                  Text(profile.mbti!, style: AppTextStyles.caption),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? context.cs.error : context.cs.onSurface;
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label, style: AppTextStyles.body.copyWith(color: color)),
      trailing: isDestructive
          ? null
          : Icon(CupertinoIcons.chevron_right, color: context.cs.onSurfaceVariant),
      onTap: onTap,
    );
  }
}