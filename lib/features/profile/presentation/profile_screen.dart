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
            child: const Text('로그아웃',
                style: TextStyle(color: AppColors.meetoryPink)),
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
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('회원 탈퇴'),
        content: const Text('정말 탈퇴하시겠어요?\n모든 데이터가 삭제됩니다.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('탈퇴',
                style: TextStyle(color: AppColors.meetoryPink)),
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
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('탈퇴 실패: $e')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(myProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('프로필'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: profileAsync.when(
        data: (profile) => ListView(
          children: [
            _buildProfileHeader(context, profile),
            const SizedBox(height: 8),
            const Divider(height: 1),

            _MenuTile(
              icon: CupertinoIcons.pencil,
              label: '내 정보 수정',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const EditProfileScreen()),
              ),
            ),

            _MenuTile(
              icon: CupertinoIcons.heart,
              label: '관심사 재설정',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                    const SurveyQuestionsScreen(isEdit: true)),
              ),
            ),

            _MenuTile(
              icon: CupertinoIcons.bell,
              label: '알림 설정',
              onTap: () {},
            ),

            _MenuTile(
              icon: Icons.block_flipped,
              label: '차단 관리',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const BlockedUsersScreen()),
              ),
            ),

            const Divider(height: 1),

            _MenuTile(
              icon: CupertinoIcons.square_arrow_right,
              label: '로그아웃',
              isDestructive: true,
              onTap: () => _logout(context, ref),
            ),

            _MenuTile(
              icon: CupertinoIcons.delete,
              label: '회원 탈퇴',
              isDestructive: true,
              onTap: () => _deleteAccount(context, ref),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('오류: $e')),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, UserProfile profile) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 20, 24, 10),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.meetorySkyBlue.withOpacity(0.1),
            AppColors.meetoryPink.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          ProfileAvatar(imageId: profile.profileImg, radius: 36),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(profile.nickname,
                    style: AppTextStyles.headline2),
                if (profile.typeLabel != null)
                  Text(profile.typeLabel!,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.meetorySkyBlue,
                      )),
                if (profile.mbti != null)
                  Text(profile.mbti!, style: AppTextStyles.caption),
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
    final color = isDestructive
        ? AppColors.meetoryPink
        : AppColors.meetoryNavy;

    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label,
          style: TextStyle(color: color)),
      trailing: isDestructive
          ? null
          : Icon(CupertinoIcons.chevron_right,
          color: Colors.grey.withOpacity(0.5)),
      onTap: onTap,
    );
  }
}