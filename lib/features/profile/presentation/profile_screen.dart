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
import 'edit_profile_screen.dart';
import '../../auth/presentation/survey_questions_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final theme = Theme.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: theme.cardColor,
        title: Text('로그아웃', style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
        content: Text('정말 로그아웃하시겠어요?', style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('취소', style: TextStyle(color: theme.textTheme.bodyMedium?.color)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('로그아웃', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    SocketClient.disconnect();
    await SecureStorage.clearAll();

    ref.invalidate(myProfileProvider);
    ref.invalidate(myGroupsProvider);
    ref.invalidate(footprintsProvider);

    if (!context.mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
    );
  }

  Future<void> _deleteAccount(BuildContext context, WidgetRef ref) async {
    final theme = Theme.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: theme.cardColor,
        title: Text('회원 탈퇴', style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
        content: Text('정말 탈퇴하시겠어요?\n모든 데이터가 삭제되고 되돌릴 수 없어요.', style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('취소', style: TextStyle(color: theme.textTheme.bodyMedium?.color))
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('탈퇴', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ProfileRepository().deleteAccount();
      SocketClient.disconnect();
      await SecureStorage.clearAll();
      ref.invalidate(myProfileProvider);
      ref.invalidate(myGroupsProvider);
      ref.invalidate(footprintsProvider);
      if (!context.mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('탈퇴 실패: $e'), backgroundColor: Colors.redAccent));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(myProfileProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('프로필'),
      ),
      body: profileAsync.when(
        data: (profile) => ListView(
          children: [
            _buildProfileHeader(context, profile, theme),
            const SizedBox(height: 12),
            Divider(height: 1, color: theme.dividerColor),
            _MenuTile(
              theme: theme,
              icon: CupertinoIcons.pencil,
              label: '내 정보 수정',
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const EditProfileScreen())),
            ),
            _MenuTile(
              theme: theme,
              icon: CupertinoIcons.heart,
              label: '관심사 재설정',
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SurveyQuestionsScreen(isEdit: true))),
            ),
            _MenuTile(
              theme: theme,
              icon: CupertinoIcons.bell,
              label: '알림 설정',
              onTap: () {},
            ),
            _MenuTile(
              theme: theme,
              icon: Icons.block_flipped,
              label: '차단 관리',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BlockedUsersScreen()),
              ),
            ),
            _MenuTile(
              theme: theme,
              icon: CupertinoIcons.question_circle,
              label: '이용 가이드',
              onTap: () {},
            ),
            Divider(height: 1, color: theme.dividerColor),
            _MenuTile(
              theme: theme,
              icon: CupertinoIcons.square_arrow_right,
              label: '로그아웃',
              isDestructive: true,
              onTap: () => _logout(context, ref),
            ),
            _MenuTile(
              theme: theme,
              icon: CupertinoIcons.delete,
              label: '회원 탈퇴',
              isDestructive: true,
              onTap: () => _deleteAccount(context, ref),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text('프로필을 불러오지 못했어요: $e',
                style: AppTextStyles.caption.copyWith(color: theme.textTheme.bodyMedium?.color)),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, UserProfile profile, ThemeData theme) {
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
                Text(profile.nickname, style: AppTextStyles.headline2.copyWith(color: theme.textTheme.bodyLarge?.color)),
                if (profile.typeLabel != null) ...[
                  const SizedBox(height: 4),
                  Text(profile.typeLabel!,
                      style: AppTextStyles.body.copyWith(
                        color: theme.primaryColor,
                        fontWeight: FontWeight.w600,
                      )),
                ],
                if (profile.mbti != null) ...[
                  const SizedBox(height: 2),
                  Text(profile.mbti!, style: AppTextStyles.caption.copyWith(color: theme.textTheme.bodyMedium?.color)),
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
  final ThemeData theme;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _MenuTile({
    required this.theme,
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? Colors.redAccent : theme.textTheme.bodyLarge?.color;
    return ListTile(
      tileColor: theme.scaffoldBackgroundColor, // 배경 칙칙함 방지
      leading: Icon(icon, color: color),
      title: Text(label, style: AppTextStyles.body.copyWith(color: color)),
      trailing: isDestructive
          ? null
          : Icon(CupertinoIcons.chevron_right, color: theme.textTheme.bodyMedium?.color),
      onTap: onTap,
    );
  }
}