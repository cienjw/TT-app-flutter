import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../domain/chat_provider.dart';
import '../data/group_repository.dart';
import 'chat_room_screen.dart';

class ChatroomsScreen extends ConsumerStatefulWidget {
  const ChatroomsScreen({super.key});

  @override
  ConsumerState<ChatroomsScreen> createState() => _ChatroomsScreenState();
}

class _ChatroomsScreenState extends ConsumerState<ChatroomsScreen> {
  bool _bluetoothOn = false;
  bool _isMatching = false;

  Future<void> _runMatching() async {
    setState(() => _isMatching = true);
    try {
      await ref.read(groupRepoProvider).joinMatching();
      // 목록 새로고침
      ref.invalidate(myGroupsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('새로운 모임에 매칭되었어요!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('매칭 실패: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isMatching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupsAsync = ref.watch(myGroupsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('채팅방'),
        titleTextStyle: AppTextStyles.headline2,
        actions: [
          IconButton(icon: const Icon(CupertinoIcons.search), onPressed: () {}),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(myGroupsProvider),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          children: [
            _buildBluetoothToggle(),
            const SizedBox(height: 16),
            _buildMatchingCard(),
            const SizedBox(height: 24),

            groupsAsync.when(
              data: (groups) => groups.isEmpty
                  ? _emptyState()
                  : Column(
                children: groups
                    .map((g) => _buildRoomCard(g))
                    .toList(),
              ),
              loading: () => const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(20),
                child: Text('목록을 불러오지 못했어요: $e',
                    style: AppTextStyles.caption),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBluetoothToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      child: Row(
        children: [
          Icon(Icons.bluetooth,
              color: _bluetoothOn ? AppColors.primary : AppColors.textHint),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('블루투스 연결 상태', style: AppTextStyles.title),
                const SizedBox(height: 2),
                Text('주변에 관심사 맞는 사람이 있으면 알림이 울려요',
                    style: AppTextStyles.caption),
              ],
            ),
          ),
          Switch(
            value: _bluetoothOn,
            activeColor: AppColors.primary,
            onChanged: (v) => setState(() => _bluetoothOn = v),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text('채팅방 매칭', style: AppTextStyles.title),
          const SizedBox(height: 4),
          Text('마음에 맞는 친구들을 찾아볼까요?',
              style: AppTextStyles.caption),
          const SizedBox(height: 16),
          SizedBox(
            width: 160,
            height: 44,
            child: FilledButton(
              onPressed: _isMatching ? null : _runMatching,
              child: _isMatching
                  ? const SizedBox(
                  width: 18, height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
                  : const Text('매칭하기'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomCard(GroupSummary group) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatRoomScreen(
            groupId: group.id,
            groupName: group.name,
            memberCount: group.memberCount,
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surfaceVariant),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: AppColors.primaryLight,
              child: Icon(CupertinoIcons.person_3_fill, color: AppColors.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${group.name} (${group.memberCount}명)',
                      style: AppTextStyles.title),
                  const SizedBox(height: 4),
                  Text(
                    group.lastMessage ?? '아직 대화가 없어요',
                    style: AppTextStyles.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(CupertinoIcons.chevron_right, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Text('아직 참여한 채팅방이 없어요.\n매칭하기를 눌러 시작해보세요!',
            textAlign: TextAlign.center, style: AppTextStyles.caption),
      ),
    );
  }
}