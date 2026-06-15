import 'package:flutter/material.dart';
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

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('로그아웃', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('정말 로그아웃하시겠어요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('로그아웃', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(myProfileProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('마이페이지', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 20)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppColors.textPrimary),
            onPressed: () {},
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: profileAsync.when(
        data: (profile) => ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          children: [
            const SizedBox(height: 16),
            _buildProfileHeader(context, profile),
            const SizedBox(height: 36),
            const Text('계정 설정', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
            const SizedBox(height: 12),
            _buildMenuSection([
              _MenuTile(icon: Icons.edit_rounded, label: '내 정보 수정', onTap: () {}),
              _MenuTile(icon: Icons.notifications_rounded, label: '알림 설정', onTap: () {}),
              _MenuTile(icon: Icons.block_rounded, label: '차단 관리', onTap: () {}),
            ]),
            const SizedBox(height: 28),
            const Text('기타', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
            const SizedBox(height: 12),
            _buildMenuSection([
              _MenuTile(icon: Icons.help_rounded, label: '이용 가이드', onTap: () {}),
              _MenuTile(icon: Icons.info_rounded, label: '앱 정보', onTap: () {}),
              _MenuTile(icon: Icons.logout_rounded, label: '로그아웃', isDestructive: true, onTap: () => _logout(context, ref)),
            ]),
            const SizedBox(height: 40),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue)),
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
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryBlue.withOpacity(0.1), AppColors.primaryBlue.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.primaryBlue.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          ProfileAvatar(radius: 44, imageId: profile.avatarId),
          const SizedBox(height: 20),
          Text(profile.nickname, style: AppTextStyles.headline2.copyWith(fontSize: 24)),
          const SizedBox(height: 8),
          if (profile.mbti != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryPink.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                profile.mbti!,
                style: const TextStyle(color: AppColors.primaryPink, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1),
              ),
            ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: profile.interests.isEmpty
                ? [const Text('관심사를 설정해보세요', style: AppTextStyles.caption)]
                : profile.interests.map((interest) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5)],
              ),
              child: Text(
                interest,
                style: const TextStyle(fontSize: 13, color: AppColors.primaryBlue, fontWeight: FontWeight.bold),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.lightGrey.withOpacity(0.5),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(children: children),
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
    final color = isDestructive ? AppColors.error : AppColors.textPrimary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(label, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w500)),
            ),
            if (!isDestructive)
              const Icon(Icons.chevron_right_rounded, color: AppColors.textHint, size: 22),
          ],
        ),
      ),
    );
  }
}
