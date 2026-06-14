import 'dart:async';
import 'package:flutter/material.dart';
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
  bool _isWaiting = false;
  double _matchThreshold = 0.85;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _checkMatchingStatus();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkMatchingStatus() async {
    try {
      final status = await ref.read(groupRepoProvider).getMatchingStatus();
      if (!mounted) return;
      if (status == 'waiting') {
        setState(() => _isWaiting = true);
        _startPolling();
      }
    } catch (_) {}
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (!mounted) return;
      ref.invalidate(myGroupsProvider);
      try {
        final status = await ref.read(groupRepoProvider).getMatchingStatus();
        if (!mounted) return;
        if (status != 'waiting') {
          _stopWaiting();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('매칭 완료! 새 모임이 열렸어요.')),
          );
        }
      } catch (_) {}
    });
  }

  void _stopWaiting() {
    _pollTimer?.cancel();
    _pollTimer = null;
    if (mounted) setState(() => _isWaiting = false);
  }

  Future<void> _runMatching() async {
    setState(() => _isMatching = true);
    try {
      await ref.read(groupRepoProvider).joinMatching(threshold: _matchThreshold);
      if (!mounted) return;
      setState(() => _isWaiting = true);
      _startPolling();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('대기열에 등록됐어요. 맞는 사람을 찾는 중...')),
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

  Future<void> _cancelMatching() async {
    _pollTimer?.cancel();
    _pollTimer = null;
    try {
      await ref.read(groupRepoProvider).cancelMatching();
    } catch (_) {}
    if (!mounted) return;
    setState(() => _isWaiting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('매칭 대기를 취소했어요.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final groupsAsync = ref.watch(myGroupsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('채팅'),
        actions: [
          IconButton(icon: const Icon(Icons.search_rounded), onPressed: () {}),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(myGroupsProvider),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          children: [
            const SizedBox(height: 8),
            _buildMatchingSection(),
            const SizedBox(height: 32),
            Text('참여 중인 대화', style: AppTextStyles.title),
            const SizedBox(height: 16),
            groupsAsync.when(
              data: (groups) => groups.isEmpty
                  ? _emptyState()
                  : Column(children: groups.map((g) => _buildRoomCard(g)).toList()),
              loading: () => const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(20),
                child: Text('목록을 불러오지 못했어요: $e', style: AppTextStyles.caption),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchingSection() {
    if (_isWaiting) return _buildWaitingCard();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.backgroundBlue.withOpacity(0.3),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, color: AppColors.primaryBlue, size: 20),
              const SizedBox(width: 8),
              Text('새로운 매칭', style: AppTextStyles.title.copyWith(color: AppColors.primaryBlue)),
            ],
          ),
          const SizedBox(height: 12),
          Text('주변의 새로운 친구들과 대화를 시작해보세요.', style: AppTextStyles.bodySmall),
          const SizedBox(height: 24),
          
          // Bluetooth Toggle
          Row(
            children: [
              Icon(Icons.location_on_rounded, 
                  color: _bluetoothOn ? AppColors.primaryPink : AppColors.textHint),
              const SizedBox(width: 12),
              Expanded(
                child: Text('주변 친구 우선 탐색', style: AppTextStyles.body.copyWith(fontSize: 15)),
              ),
              Switch(
                value: _bluetoothOn,
                activeColor: AppColors.primaryPink,
                onChanged: (v) => setState(() => _bluetoothOn = v),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Slider
          Row(
            children: [
              Text('관심사 일치도', style: AppTextStyles.body.copyWith(fontSize: 15)),
              const Spacer(),
              Text('${(_matchThreshold * 100).round()}%', 
                  style: const TextStyle(color: AppColors.primaryPink, fontWeight: FontWeight.bold)),
            ],
          ),
          Slider(
            value: _matchThreshold,
            min: 0.5,
            max: 1.0,
            activeColor: AppColors.primaryPink,
            inactiveColor: AppColors.primaryPink.withOpacity(0.1),
            onChanged: (v) => setState(() => _matchThreshold = v),
          ),
          
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isMatching ? null : _runMatching,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              minimumSize: const Size(double.infinity, 52),
            ),
            child: _isMatching
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('매칭 시작하기'),
          ),
        ],
      ),
    );
  }

  Widget _buildWaitingCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.backgroundBlue.withOpacity(0.3),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          const SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          Text('매칭 대기 중...', style: AppTextStyles.title),
          const SizedBox(height: 8),
          Text('딱 맞는 인연을 찾고 있어요.', style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: _cancelMatching,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.primaryBlue),
              foregroundColor: AppColors.primaryBlue,
              minimumSize: const Size(double.infinity, 52),
            ),
            child: const Text('취소하기'),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomCard(GroupSummary group) {
    return InkWell(
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
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.lightGrey),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.backgroundBlue,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.groups_rounded, color: AppColors.primaryBlue, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(group.name, style: AppTextStyles.title.copyWith(fontSize: 16)),
                      const SizedBox(width: 6),
                      Text('${group.memberCount}', style: TextStyle(color: AppColors.primaryPink, fontSize: 13, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    group.lastMessage ?? '첫 메시지를 보내보세요!',
                    style: AppTextStyles.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.chat_bubble_outline_rounded, size: 48, color: AppColors.textHint.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text('참여 중인 대화가 없습니다.', style: AppTextStyles.bodySmall),
          ],
        ),
      ),
    );
  }
}
