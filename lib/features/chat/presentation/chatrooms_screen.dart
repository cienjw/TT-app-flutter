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
  bool _isMatching = false;
  bool _isWaiting = false;
  double _matchThreshold = 0.85;
  Timer? _pollTimer;
  bool _isSearching = false;
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _checkMatchingStatus();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _searchCtrl.dispose();
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
    final theme = Theme.of(context);
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
        SnackBar(content: Text('매칭 실패: $e'), backgroundColor: Colors.redAccent),
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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
          controller: _searchCtrl,
          autofocus: true,
          style: AppTextStyles.body.copyWith(color: theme.textTheme.bodyLarge?.color),
          cursorColor: theme.primaryColor,
          decoration: InputDecoration(
            hintText: '채팅방 이름 검색',
            border: InputBorder.none,
            hintStyle: AppTextStyles.body.copyWith(color: theme.textTheme.bodyMedium?.color),
          ),
          onChanged: (v) => setState(() => _searchQuery = v),
        )
            : const Text('채팅방'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? CupertinoIcons.xmark : CupertinoIcons.search),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchQuery = '';
                  _searchCtrl.clear();
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(myGroupsProvider),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          children: [
            if (!_isSearching) ...[
              _buildMatchingCard(theme),
              const SizedBox(height: 24),
            ],
            groupsAsync.when(
              data: (groups) {
                final filtered = _searchQuery.isEmpty
                    ? groups
                    : groups.where((g) => g.name.contains(_searchQuery)).toList();
                if (groups.isEmpty) return _emptyState(theme);
                if (filtered.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Text("'$_searchQuery'와 일치하는 채팅방이 없어요",
                          style: AppTextStyles.caption.copyWith(color: theme.textTheme.bodyMedium?.color)),
                    ),
                  );
                }
                return Column(children: filtered.map((g) => _buildRoomCard(g, theme)).toList());
              },
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

  Widget _buildMatchingCard(ThemeData theme) {
    if (_isWaiting) return _buildWaitingCard(theme);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('채팅방 매칭', style: AppTextStyles.title.copyWith(color: theme.textTheme.bodyLarge?.color)),
          const SizedBox(height: 4),
          Text('마음에 맞는 친구들을 찾아볼까요?', style: AppTextStyles.caption.copyWith(color: theme.textTheme.bodyMedium?.color)),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.bluetooth,
                    size: 22,
                    color: _bluetoothOn ? theme.primaryColor : theme.textTheme.bodyMedium?.color),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('주변 탐색', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600, color: theme.textTheme.bodyLarge?.color)),
                      Text('가까이 있는 사람을 우선 찾아요', style: AppTextStyles.caption.copyWith(color: theme.textTheme.bodyMedium?.color)),
                    ],
                  ),
                ),
                Switch(
                  value: _bluetoothOn,
                  activeColor: theme.primaryColor,
                  onChanged: (v) => setState(() => _bluetoothOn = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Text('관심사 일치도', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600, color: theme.textTheme.bodyLarge?.color)),
              const Spacer(),
              Text('${(_matchThreshold * 100).round()}% 이상',
                  style: AppTextStyles.body.copyWith(color: theme.primaryColor, fontWeight: FontWeight.w700)),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              activeTrackColor: theme.primaryColor,
              inactiveTrackColor: theme.dividerColor,
              thumbColor: theme.primaryColor,
              overlayColor: theme.primaryColor.withOpacity(0.15),
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
            style: AppTextStyles.caption.copyWith(color: theme.textTheme.bodyMedium?.color),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              style: FilledButton.styleFrom(backgroundColor: theme.primaryColor),
              onPressed: _isMatching ? null : _runMatching,
              child: _isMatching
                  ? SizedBox(
                  width: 18, height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: theme.brightness == Brightness.dark ? Colors.black : Colors.white))
                  : Text('매칭하기', style: TextStyle(color: theme.brightness == Brightness.dark ? Colors.black : Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaitingCard(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border.all(color: theme.primaryColor.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('맞는 친구를 찾는 중', style: AppTextStyles.title.copyWith(color: theme.textTheme.bodyLarge?.color)),
              const SizedBox(width: 10),
              _PulsingDots(color: theme.primaryColor),
            ],
          ),
          const SizedBox(height: 8),
          Text('조건에 맞는 사람이 모이면 자동으로 모임이 열려요',
              textAlign: TextAlign.center, style: AppTextStyles.caption.copyWith(color: theme.textTheme.bodyMedium?.color)),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.primaryColor,
                side: BorderSide(color: theme.primaryColor),
              ),
              onPressed: _cancelMatching,
              child: const Text('매칭 취소'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomCard(GroupSummary group, ThemeData theme) {
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
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: theme.dividerColor.withOpacity(0.2),
              child: Icon(CupertinoIcons.person_3_fill, color: theme.textTheme.bodyMedium?.color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${group.name} (${group.memberCount}명)', style: AppTextStyles.title.copyWith(color: theme.textTheme.bodyLarge?.color)),
                  const SizedBox(height: 4),
                  Text(group.lastMessage ?? '아직 대화가 없어요',
                      style: AppTextStyles.caption.copyWith(color: theme.textTheme.bodyMedium?.color),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Icon(CupertinoIcons.chevron_right, color: theme.textTheme.bodyMedium?.color),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Text('아직 참여한 채팅방이 없어요.\n매칭하기를 눌러 시작해보세요!',
            textAlign: TextAlign.center, style: AppTextStyles.caption.copyWith(color: theme.textTheme.bodyMedium?.color)),
      ),
    );
  }
}

class _PulsingDots extends StatefulWidget {
  final Color color;
  const _PulsingDots({required this.color});

  @override
  State<_PulsingDots> createState() => _PulsingDotsState();
}

class _PulsingDotsState extends State<_PulsingDots> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat();
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