import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/profile_avatar.dart';
import '../../chat/data/group_repository.dart';
import '../../chat/domain/chat_provider.dart';

class BlockedUsersScreen extends ConsumerStatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  ConsumerState<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends ConsumerState<BlockedUsersScreen> {
  late Future<List<GroupMember>> _future;

  @override
  void initState() {
    super.initState();
    _future = ref.read(groupRepoProvider).getBlockedUsers();
  }

  void _reload() {
    setState(() => _future = ref.read(groupRepoProvider).getBlockedUsers());
  }

  Future<void> _unblock(GroupMember m) async {
    try {
      await ref.read(groupRepoProvider).unblockUser(m.id);
      if (!mounted) return;
      _reload();
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${m.nickname} 차단을 해제했어요.')));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('해제 실패: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('차단한 사용자'),
        titleTextStyle: AppTextStyles.headline2,
      ),
      body: FutureBuilder<List<GroupMember>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text('목록을 불러오지 못했어요: ${snap.error}',
                    style: AppTextStyles.caption),
              ),
            );
          }
          final blocked = snap.data ?? [];
          if (blocked.isEmpty) {
            return Center(
              child: Text('차단한 사용자가 없어요', style: AppTextStyles.caption),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: blocked.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final m = blocked[i];
              return ListTile(
                leading: ProfileAvatar(imageId: m.profileImg, radius: 20),
                title: Text(m.nickname, style: AppTextStyles.body),
                trailing: OutlinedButton(
                  onPressed: () => _unblock(m),
                  child: const Text('차단 해제'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}