import 'dart:async';
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
  bool _isMatching = false; // enqueue 요청 중
  bool _isWaiting = false;  // 대기열에 올라가 있음
  double _matchThreshold = 0.85;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _checkMatchingStatus(); // 화면 진입 시 이미 대기 중인지 복원
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
    } catch (_) {/* 무시 */}
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (!mounted) return;
      ref.invalidate(myGroupsProvider); // 새 방 생기면 목록에 반영
      try {
        final status = await ref.read(groupRepoProvider).getMatchingStatus();
        if (!mounted) return;
        if (status != 'waiting') {
          _stopWaiting();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('매칭 완료! 새 모임이 열렸어요.')),
          );
        }
      } catch (_) {/* 무시 */}
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
        SnackBar(content: Text('매칭 실패: $e'), backgroundColor: context.cs.error),
      );
    } finally {
      if (mounted) setState(() => _isMatching = false);
    }
  }

  Future<void> _cancelMatching() async {
    _pollTimer?.cancel(); // 취소를 매칭완료로 오인하지 않게 먼저 멈춤
    _pollTimer = null;
    try {
      await ref.read(groupRepoProvider).cancelMatching();
    } catch (_) {/* 무시 */}
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
            _buildMatchingCard(),
            const SizedBox(height: 24),
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

  Widget _buildMatchingCard() {
    if (_isWaiting) return _buildWaitingCard();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('채팅방 매칭', style: AppTextStyles.title),
          const SizedBox(height: 4),
          Text('마음에 맞는 친구들을 찾아볼까요?', style: AppTextStyles.caption),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: context.cs.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.bluetooth,
                    size: 22,
                    color: _bluetoothOn
                        ? context.cs.primary
                        : context.cs.onSurfaceVariant),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('주변 탐색',
                          style: AppTextStyles.body
                              .copyWith(fontWeight: FontWeight.w600)),
                      Text('가까이 있는 사람을 우선 찾아요',
                          style: AppTextStyles.caption),
                    ],
                  ),
                ),
                Switch(
                  value: _bluetoothOn,
                  activeColor: context.cs.primary,
                  onChanged: (v) => setState(() => _bluetoothOn = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Text('관심사 일치도',
                  style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
              const Spacer(),
              Text('${(_matchThreshold * 100).round()}% 이상',
                  style: AppTextStyles.body.copyWith(
                      color: context.cs.primary, fontWeight: FontWeight.w700)),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              activeTrackColor: context.cs.primary,
              inactiveTrackColor: context.cs.surface,
              thumbColor: context.cs.primary,
              overlayColor: context.cs.primary.withOpacity(0.15),
            ),
            child: Slider(
              value: _matchThreshold,
              min: 0.5,
              max: 1.0,
              divisions: 10,
              onChanged: (v) => setState(() => _matchThreshold = v),
            ),
          ),
          Text(
            _matchThreshold >= 0.99
                ? '나와 완벽히 일치하는 사람만 기다려요'
                : '관심사가 ${(_matchThreshold * 100).round()}% 이상 맞는 사람과 연결돼요',
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: _isMatching ? null : _runMatching,
              child: _isMatching
                  ? SizedBox(
                  width: 18, height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: context.cs.onPrimary))
                  : const Text('매칭하기'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaitingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('맞는 친구를 찾는 중', style: AppTextStyles.title),
              const SizedBox(width: 10),
              _PulsingDots(color: context.cs.primary),
            ],
          ),
          const SizedBox(height: 8),
          Text('조건에 맞는 사람이 모이면 자동으로 모임이 열려요',
              textAlign: TextAlign.center, style: AppTextStyles.caption),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: _cancelMatching,
              child: const Text('매칭 취소'),
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
          color: context.cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.cs.surfaceContainerHighest),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: context.cs.surfaceContainerHighest,
              child: Icon(CupertinoIcons.person_3_fill,
                  color: context.cs.onSurfaceVariant),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${group.name} (${group.memberCount}명)',
                      style: AppTextStyles.title),
                  const SizedBox(height: 4),
                  Text(group.lastMessage ?? '아직 대화가 없어요',
                      style: AppTextStyles.caption,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Icon(CupertinoIcons.chevron_right, color: context.cs.onSurfaceVariant),
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

// 대기 중 맥동하는 점 3개
class _PulsingDots extends StatefulWidget {
  final Color color;
  const _PulsingDots({required this.color});

  @override
  State<_PulsingDots> createState() => _PulsingDotsState();
}

class _PulsingDotsState extends State<_PulsingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000))
      ..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _c,
          builder: (_, __) {
            final t = (_c.value - i * 0.18) % 1.0;
            final pulse = (1 - (t - 0.5).abs() * 2).clamp(0.0, 1.0);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: 7, height: 7,
              decoration: BoxDecoration(
                color: widget.color.withOpacity(0.3 + 0.7 * pulse),
                shape: BoxShape.circle,
              ),
            );
          },
        );
      }),
    );
  }
}