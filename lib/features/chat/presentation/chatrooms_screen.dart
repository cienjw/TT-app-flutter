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
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          '채팅',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded, color: AppColors.textPrimary),
            onPressed: () {},
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(myGroupsProvider),
        color: AppColors.primaryBlue,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          children: [
            const SizedBox(height: 12),
            _buildMatchingSection(),
            const SizedBox(height: 36),
            Row(
              children: [
                Text('참여 중인 대화', style: AppTextStyles.title),
                const SizedBox(width: 8),
                groupsAsync.when(
                  data: (groups) => groups.isNotEmpty 
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: AppColors.primaryBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                        child: Text('${groups.length}', style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold, fontSize: 12)),
                      )
                    : const SizedBox.shrink(),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            groupsAsync.when(
              data: (groups) => groups.isEmpty
                  ? _emptyState()
                  : Column(children: groups.map((g) => _buildRoomCard(g)).toList()),
              loading: () => const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator(color: AppColors.primaryBlue)),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(20),
                child: Text('목록을 불러오지 못했어요: $e', style: AppTextStyles.caption),
              ),
            ),
            const SizedBox(height: 40),
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
        color: AppColors.backgroundBlue.withOpacity(0.5),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.primaryBlue.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, color: AppColors.primaryBlue, size: 22),
              const SizedBox(width: 10),
              Text('실시간 매칭', style: AppTextStyles.title.copyWith(color: AppColors.primaryBlue)),
            ],
          ),
          const SizedBox(height: 12),
          Text('나와 잘 맞는 친구를 실시간으로 찾아드릴게요.', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 28),
          
          // Bluetooth Toggle
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.bluetooth_rounded, 
                    color: _bluetoothOn ? AppColors.primaryBlue : AppColors.textHint, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text('주변 친구 우선 탐색', style: AppTextStyles.body.copyWith(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
              Switch(
                value: _bluetoothOn,
                activeColor: AppColors.primaryBlue,
                onChanged: (v) => setState(() => _bluetoothOn = v),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Slider
          Row(
            children: [
              const Text('관심사 일치도', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              const Spacer(),
              Text('${(_matchThreshold * 100).round()}%', 
                  style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          Slider(
            value: _matchThreshold,
            min: 0.5,
            max: 1.0,
            activeColor: AppColors.primaryBlue,
            inactiveColor: AppColors.primaryBlue.withOpacity(0.1),
            onChanged: (v) => setState(() => _matchThreshold = v),
          ),
          
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _isMatching ? null : _runMatching,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              elevation: 0,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: _isMatching
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('지금 매칭 시작하기', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildWaitingCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.backgroundBlue.withOpacity(0.5),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.primaryBlue.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          const SizedBox(
            width: 56,
            height: 56,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
              strokeWidth: 4,
            ),
          ),
          const SizedBox(height: 28),
          const Text('매칭 대기 중...', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryBlue)),
          const SizedBox(height: 10),
          Text('딱 맞는 인연을 찾고 있어요.\n잠시만 기다려주세요!', style: AppTextStyles.bodySmall.copyWith(height: 1.5), textAlign: TextAlign.center),
          const SizedBox(height: 32),
          TextButton(
            onPressed: _cancelMatching,
            child: Text('매칭 취소하기', style: TextStyle(color: AppColors.textHint, decoration: TextDecoration.underline)),
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
      borderRadius: BorderRadius.circular(24),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.lightGrey.withOpacity(0.8)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.backgroundBlue,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.groups_rounded, color: AppColors.primaryBlue, size: 30),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(group.name, style: AppTextStyles.title.copyWith(fontSize: 17), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      const SizedBox(width: 8),
                      Text('${group.memberCount}', style: const TextStyle(color: AppColors.primaryBlue, fontSize: 13, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    group.lastMessage ?? '첫 메시지를 보내보세요!',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textHint, size: 24),
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
            Icon(Icons.chat_bubble_outline_rounded, size: 56, color: AppColors.textHint.withOpacity(0.3)),
            const SizedBox(height: 20),
            Text('참여 중인 대화가 없어요.\n새로운 매칭을 시작해보세요!', style: AppTextStyles.bodySmall.copyWith(height: 1.5), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
