import 'package:flutter/material.dart';
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
  List<GroupMember>? _blocked;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final list = await ref.read(groupRepoProvider).getBlockedUsers();
      if (!mounted) return;
      setState(() { _blocked = list; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = '$e'; _loading = false; });
    }
  }

  Future<void> _unblock(GroupMember m) async {
    try {
      await ref.read(groupRepoProvider).unblockUser(m.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${m.nickname} 차단을 해제했어요.')));
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('해제 실패: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final blocked = _blocked ?? [];
    return Scaffold(
      appBar: AppBar(
        title: Text('차단한 사용자',
            style: AppTextStyles.headline2.copyWith(color: context.cs.onSurface)),
      ),
      body: Column(
        children: [
          // 🔴 임시 디버그 배너 (원인 확인 후 제거)
          Container(
            width: double.infinity,
            color: Colors.red,
            padding: const EdgeInsets.all(8),
            child: Text(
              'loading=$_loading / error=$_error / count=${_blocked?.length}',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
          Expanded(
            child: _loading
                ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: context.cs.onSurface),
                      const SizedBox(height: 12),
                      Text('불러오는 중...',
                          style: AppTextStyles.body.copyWith(color: context.cs.onSurface)),
                    ],
                  ),
                )
                : _error != null
                ? Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text('불러오기 실패:\n$_error',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: context.cs.error, fontSize: 14)),
              ),
            )
                : blocked.isEmpty
                ? Center(
              child: Text('차단한 사용자가 없어요',
                  style: AppTextStyles.body
                      .copyWith(color: context.cs.onSurfaceVariant)),
            )
                : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: blocked.length,
              separatorBuilder: (_, __) => Divider(
                  height: 1, color: context.cs.surfaceContainerHighest),
              itemBuilder: (context, i) {
                final m = blocked[i];
                return ListTile(
                  leading: ProfileAvatar(imageId: m.profileImg, radius: 20),
                  title: Text(m.nickname,
                      style: AppTextStyles.body
                          .copyWith(color: context.cs.onSurface)),
                  trailing: OutlinedButton(
                    onPressed: () => _unblock(m),
                    child: const Text('차단 해제'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}