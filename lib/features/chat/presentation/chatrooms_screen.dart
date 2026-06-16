import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../domain/chat_provider.dart';
import '../data/group_repository.dart';
import 'chat_room_screen.dart';
import '../../../core/storage/secure_storage.dart';

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
    _loadThreshold();
    _checkMatchingStatus();
  }

  Future<void> _loadThreshold() async {
    final saved = await SecureStorage.getMatchThreshold();
    if (saved != null && mounted) setState(() => _matchThreshold = saved);
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
    try {
      await SecureStorage.setMatchThreshold(_matchThreshold);
      await ref
          .read(groupRepoProvider)
          .joinMatching(threshold: _matchThreshold);
      if (!mounted) return;
      setState(() => _isWaiting = true);
      _startPolling();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('대기열에 등록됐어요. 맞는 사람을 찾는 중...')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('매칭 실패: $e'), backgroundColor: context.cs.error),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
          controller: _searchCtrl,
          autofocus: true,
          style: AppTextStyles.body,
          cursorColor: context.cs.primary,
          decoration: InputDecoration(
            hintText: '채팅방 이름 검색',
            border: InputBorder.none,
            hintStyle: AppTextStyles.body
                .copyWith(color: context.cs.onSurfaceVariant),
          ),
          onChanged: (v) => setState(() => _searchQuery = v),
        )
            : Text('채팅방', style: AppTextStyles.title),
        actions: [
          IconButton(
            icon: Icon(
              _isSearching
                  ? CupertinoIcons.xmark
                  : CupertinoIcons.search,
              size: 22,
            ),
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
              const SizedBox(height: 4),
              _buildMatchingCard(isDark),
              const SizedBox(height: 28),
              // 채팅방 섹션 헤더
              groupsAsync.when(
                data: (groups) {
                  if (groups.isEmpty) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Text('참여 중인 채팅방',
                            style: AppTextStyles.body.copyWith(
                              fontWeight: FontWeight.w700,
                              color: context.cs.onSurface.withOpacity(0.6),
                              fontSize: 13,
                            )),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.meetoryPink.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${groups.length}개',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.meetoryPink,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
            groupsAsync.when(
              data: (groups) {
                final filtered = _searchQuery.isEmpty
                    ? groups
                    : groups
                    .where((g) => g.name.contains(_searchQuery))
                    .toList();
                if (groups.isEmpty) return _emptyState();
                if (filtered.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Text("'$_searchQuery'와 일치하는 채팅방이 없어요",
                          style: AppTextStyles.caption),
                    ),
                  );
                }
                return Column(
                    children: filtered
                        .map((g) => _buildRoomCard(g, isDark))
                        .toList());
              },
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
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchingCard(bool isDark) {
    if (_isWaiting) return _buildWaitingCard(isDark);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
            const Color(0xFF1A2035),
            const Color(0xFF1C1C1E),
          ]
              : [
            AppColors.meetoryNavy.withOpacity(0.06),
            AppColors.meetorySkyBlue.withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? AppColors.meetorySkyBlue.withOpacity(0.15)
              : AppColors.meetoryNavy.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 카드 헤더
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        AppColors.meetorySkyBlue,
                        AppColors.meetoryNavy,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(CupertinoIcons.sparkles,
                      color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('AI 매칭',
                        style: AppTextStyles.title.copyWith(fontSize: 16)),
                    Text('마음 맞는 친구들을 찾아볼까요?',
                        style: AppTextStyles.caption.copyWith(fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Divider(
                height: 1,
                color: context.cs.onSurface.withOpacity(0.08)),
          ),
          const SizedBox(height: 18),

          // 주변 탐색 토글
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _bluetoothOn
                          ? AppColors.meetorySkyBlue.withOpacity(0.15)
                          : context.cs.onSurface.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      CupertinoIcons.bluetooth,
                      size: 18,
                      color: _bluetoothOn
                          ? AppColors.meetorySkyBlue
                          : context.cs.onSurface.withOpacity(0.35),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('주변 탐색',
                            style: AppTextStyles.body.copyWith(
                                fontWeight: FontWeight.w600, fontSize: 15)),
                        Text('가까이 있는 사람을 우선 찾아요',
                            style:
                            AppTextStyles.caption.copyWith(fontSize: 12)),
                      ],
                    ),
                  ),
                  Transform.scale(
                    scale: 0.85,
                    child: Switch.adaptive(
                      value: _bluetoothOn,
                      activeColor: AppColors.meetorySkyBlue,
                      onChanged: (v) => setState(() => _bluetoothOn = v),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 관심사 일치도 슬라이더
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('관심사 일치도',
                        style: AppTextStyles.body
                            .copyWith(fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppColors.meetorySkyBlue,
                            AppColors.meetoryNavy,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${(_matchThreshold * 100).round()}% 이상',
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4,
                    activeTrackColor: AppColors.meetorySkyBlue,
                    inactiveTrackColor:
                    context.cs.onSurface.withOpacity(0.1),
                    thumbColor: Colors.white,
                    thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 8),
                    overlayColor:
                    AppColors.meetorySkyBlue.withOpacity(0.15),
                    overlayShape:
                    const RoundSliderOverlayShape(overlayRadius: 18),
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
                  style: AppTextStyles.caption.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 매칭 버튼
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ).copyWith(
                  backgroundColor:
                  WidgetStateProperty.all(Colors.transparent),
                ),
                onPressed: _isMatching ? null : _runMatching,
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: _isMatching
                        ? null
                        : const LinearGradient(
                      colors: [
                        AppColors.meetoryNavy,
                        AppColors.meetorySkyBlue,
                      ],
                    ),
                    color: _isMatching
                        ? context.cs.onSurface.withOpacity(0.12)
                        : null,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Container(
                    alignment: Alignment.center,
                    child: _isMatching
                        ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: context.cs.onSurface))
                        : Text(
                      '매칭 시작하기',
                      style: AppTextStyles.button.copyWith(
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaitingCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
            AppColors.meetorySkyBlue.withOpacity(0.12),
            AppColors.meetoryNavy.withOpacity(0.2),
          ]
              : [
            AppColors.meetorySkyBlue.withOpacity(0.08),
            AppColors.meetoryNavy.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.meetorySkyBlue.withOpacity(0.25),
        ),
      ),
      child: Column(
        children: [
          // 애니메이션 점
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.meetorySkyBlue.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(CupertinoIcons.sparkles,
                    size: 18, color: AppColors.meetorySkyBlue),
              ),
              const SizedBox(width: 10),
              Text('맞는 친구를 찾는 중', style: AppTextStyles.title),
              const SizedBox(width: 10),
              _PulsingDots(color: AppColors.meetorySkyBlue),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '조건에 맞는 사람이 모이면 자동으로 모임이 열려요',
            textAlign: TextAlign.center,
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.meetorySkyBlue,
                side: BorderSide(
                    color: AppColors.meetorySkyBlue.withOpacity(0.5)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _cancelMatching,
              child: const Text('매칭 취소'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomCard(GroupSummary group, bool isDark) {
    // 그룹 이름 첫 글자로 아바타 색상 결정
    final colors = [
      AppColors.meetorySkyBlue,
      AppColors.meetoryPink,
      AppColors.meetoryNavy,
      const Color(0xFF80CBC4),
      const Color(0xFFB39DDB),
    ];
    final colorIdx = group.name.codeUnitAt(0) % colors.length;

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
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : Colors.black.withOpacity(0.06),
          ),
          boxShadow: isDark
              ? null
              : [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // 그룹 아바타
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: colors[colorIdx].withOpacity(isDark ? 0.2 : 0.12),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  group.name.isNotEmpty
                      ? group.name.substring(0, 1)
                      : '?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: colors[colorIdx],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          group.name,
                          style: AppTextStyles.body
                              .copyWith(fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: context.cs.onSurface.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${group.memberCount}명',
                          style: AppTextStyles.caption.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    group.lastMessage ?? '아직 대화가 없어요',
                    style: AppTextStyles.caption.copyWith(fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              CupertinoIcons.chevron_right,
              size: 14,
              color: context.cs.onSurface.withOpacity(0.25),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.meetorySkyBlue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(CupertinoIcons.chat_bubble_2,
                size: 32, color: AppColors.meetorySkyBlue),
          ),
          const SizedBox(height: 16),
          Text('아직 참여한 채팅방이 없어요',
              style: AppTextStyles.body
                  .copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text('위 매칭 카드로 새 모임을 시작해보세요!',
              style: AppTextStyles.caption),
        ],
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
              width: 7,
              height: 7,
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