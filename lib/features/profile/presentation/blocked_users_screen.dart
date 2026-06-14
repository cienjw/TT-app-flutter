import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/profile_avatar.dart';
import '../../chat/data/group_repository.dart';
import '../../chat/domain/chat_provider.dart';

class BlockedUsersScreen extends ConsumerWidget {
  const BlockedUsersScreen({super.key});

  Future<void> _unblock(BuildContext context, WidgetRef ref, GroupMember m) async {
    try {
      await ref.read(groupRepoProvider).unblockUser(m.id);
      ref.invalidate(blockedUsersProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${m.nickname} 차단을 해제했어요.')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('해제 실패: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(blockedUsersProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text('차단한 사용자',
            style: AppTextStyles.headline2.copyWith(color: context.cs.onSurface)),
      ),
      body: async.when(
        data: (blocked) => blocked.isEmpty
            ? Center(
          child: Text('차단한 사용자가 없어요',
              style: AppTextStyles.body
                  .copyWith(color: context.cs.onSurfaceVariant)),
        )
            : ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: blocked.length,
          separatorBuilder: (_, __) =>
              Divider(height: 1, color: context.cs.surfaceContainerHighest),
          itemBuilder: (context, i) {
            final m = blocked[i];
            return ListTile(
              leading: ProfileAvatar(imageId: m.profileImg, radius: 20),
              title: Text(m.nickname,
                  style: AppTextStyles.body
                      .copyWith(color: context.cs.onSurface)),
              trailing: OutlinedButton(
                onPressed: () => _unblock(context, ref, m),
                child: const Text('차단 해제'),
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text('목록을 불러오지 못했어요: $e',
                textAlign: TextAlign.center, style: AppTextStyles.caption),
          ),
        ),
      ),
    );
  }
}