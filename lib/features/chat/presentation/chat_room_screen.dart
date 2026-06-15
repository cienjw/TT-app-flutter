import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../../core/network/socket_client.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/message_repository.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/group_repository.dart';
import '../domain/chat_provider.dart';
import '../../../shared/widgets/profile_avatar.dart';

class ChatRoomScreen extends ConsumerStatefulWidget {
  final int groupId;
  final String groupName;
  final int memberCount;

  const ChatRoomScreen({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.memberCount,
  });

  @override
  ConsumerState<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends ConsumerState<ChatRoomScreen> {
  final _repo = MessageRepository();
  final _textController = TextEditingController();
  final _itemScrollController = ItemScrollController();
  final _inputFocus = FocusNode();

  final List<Message> _messages = [];
  io.Socket? _socket;
  int? _myUserId;
  bool _isLoading = true;
  Message? _replyingTo;
  int? _highlightedId;
  late String _groupName;
  final Set<int> _blockedIds = {};
  final List<GroupMember> _members = [];
  final Map<int, int> _lastRead = {};

  static const _reactionEmojis = ['❤️', '👍', '😂', '😮', '😢'];

  @override
  void initState() {
    super.initState();
    _groupName = widget.groupName;
    _init();
  }

  Future<void> _init() async {
    final token = await SecureStorage.getAccessToken();
    if (token != null) {
      final decoded = JwtDecoder.decode(token);
      final raw = decoded['userId'];
      _myUserId = switch (raw) {
        int v => v,
        double v => v.toInt(),
        String v => int.tryParse(v),
        _ => null,
      };
    }

    try {
      final history = await _repo.getMessages(widget.groupId);
      setState(() {
        _messages.addAll(history);
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() => _isLoading = false);
    }

    try {
      final blocked = await ref.read(groupRepoProvider).getBlockedUsers();
      _blockedIds.addAll(blocked.map((b) => b.id));
    } catch (_) {}

    try {
      final detail = await ref.read(groupRepoProvider).getGroupDetail(widget.groupId);
      _members..clear()..addAll(detail.members);
      for (final m in detail.members) {
        _lastRead[m.id] = m.lastReadId;
      }
    } catch (_) {}

    _socket = await SocketClient.connect();
    _socket!.emit('join_room', widget.groupId);
    _socket!.on('new_message', _onNewMessage);
    _socket!.on('reaction_updated', _onReactionUpdated);
    _socket!.on('read_updated', _onReadUpdated);
    _markReadLatest();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_messages.isNotEmpty && _itemScrollController.isAttached) {
        _itemScrollController.scrollTo(
          index: _messages.length - 1,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _scrollToMessage(int messageId) {
    final idx = _messages.indexWhere((m) => m.id == messageId);
    if (idx == -1 || !_itemScrollController.isAttached) return;
    _itemScrollController.scrollTo(
      index: idx,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      alignment: 0.3,
    );
    setState(() => _highlightedId = messageId);
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _highlightedId = null);
    });
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty || _socket == null) return;
    _socket!.emit('send_message', {
      'groupId': widget.groupId,
      'content': text,
      if (_replyingTo != null) 'replyToId': _replyingTo!.id,
    });
    _textController.clear();
    setState(() => _replyingTo = null);
  }

  void _startReply(Message msg) {
    setState(() => _replyingTo = msg);
    _inputFocus.requestFocus();
  }

  void _onNewMessage(dynamic data) {
    final msg = Message.fromJson(Map<String, dynamic>.from(data));
    if (_blockedIds.contains(msg.senderId)) return;
    setState(() => _messages.add(msg));
    _scrollToBottom();
    _markReadLatest();
  }

  void _onReactionUpdated(dynamic data) {
    final map = Map<String, dynamic>.from(data);
    final messageId = (map['messageId'] as num).toInt();
    final reactions = (map['reactions'] as List)
        .map((e) => MessageReaction.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    setState(() {
      final idx = _messages.indexWhere((m) => m.id == messageId);
      if (idx != -1) {
        _messages[idx] = _messages[idx].copyWith(reactions: reactions);
      }
    });
  }

  void _toggleReaction(int messageId, String reaction) {
    _socket?.emit('toggle_reaction', {
      'messageId': messageId,
      'reaction': reaction,
    });
  }

  void _showReactionPicker(Message msg) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _reactionEmojis.map((emoji) {
              return GestureDetector(
                onTap: () {
                  _toggleReaction(msg.id, emoji);
                  Navigator.pop(context);
                },
                child: Text(emoji, style: const TextStyle(fontSize: 32)),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  void _markReadLatest() {
    if (_messages.isEmpty || _socket == null) return;
    _socket!.emit('mark_read', {
      'groupId': widget.groupId,
      'messageId': _messages.last.id,
    });
  }

  void _onReadUpdated(dynamic data) {
    final map = Map<String, dynamic>.from(data);
    final uid = (map['userId'] as num).toInt();
    final lastId = (map['lastReadId'] as num).toInt();
    setState(() => _lastRead[uid] = lastId);
  }

  int _unreadCount(Message m) {
    if (_members.isEmpty) return 0;
    final readers = _members.where((mem) =>
    mem.id == m.senderId || (_lastRead[mem.id] ?? 0) >= m.id
    ).length;
    return _members.length - readers;
  }

  Future<void> _showMembers() async {
    final theme = Theme.of(context);
    try {
      final detail = await ref.read(groupRepoProvider).getGroupDetail(widget.groupId);
      if (!mounted) return;

      final members = [...detail.members]..sort((a, b) {
        if (a.id == _myUserId) return -1;
        if (b.id == _myUserId) return 1;
        return a.nickname.compareTo(b.nickname);
      });

      showModalBottomSheet(
        context: context,
        backgroundColor: theme.cardColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (_) => StatefulBuilder(
          builder: (context, setModalState) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('참여 멤버 ${members.length}명', style: AppTextStyles.title.copyWith(color: theme.textTheme.bodyLarge?.color)),
                  const SizedBox(height: 12),
                  ...members.map((m) {
                    final isMe = m.id == _myUserId;
                    final isBlocked = _blockedIds.contains(m.id);
                    final row = Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          ProfileAvatar(imageId: m.profileImg, radius: 20),
                          const SizedBox(width: 12),
                          Text(m.nickname, style: AppTextStyles.body.copyWith(color: theme.textTheme.bodyLarge?.color)),
                          if (isMe) ...[
                            const SizedBox(width: 6),
                            Text('(나)', style: AppTextStyles.caption.copyWith(color: theme.textTheme.bodyMedium?.color)),
                          ],
                          if (isBlocked) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: theme.dividerColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text('차단됨', style: AppTextStyles.caption.copyWith(color: theme.textTheme.bodyMedium?.color)),
                            ),
                          ],
                        ],
                      ),
                    );
                    if (isMe || isBlocked) return row;
                    return Slidable(
                      key: ValueKey(m.id),
                      endActionPane: ActionPane(
                        motion: const DrawerMotion(),
                        extentRatio: 0.5,
                        children: [
                          SlidableAction(
                            onPressed: (_) => _reportMember(m),
                            backgroundColor: theme.dividerColor,
                            foregroundColor: theme.textTheme.bodyLarge?.color,
                            icon: CupertinoIcons.exclamationmark_triangle,
                            label: '신고',
                          ),
                          SlidableAction(
                            onPressed: (_) async {
                              await _blockMember(m);
                              setModalState(() {});
                            },
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white,
                            icon: CupertinoIcons.nosign,
                            label: '차단',
                          ),
                        ],
                      ),
                      child: row,
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('멤버를 불러오지 못했어요: $e')));
      }
    }
  }

  Future<void> _reportMember(GroupMember m) async {
    final theme = Theme.of(context);
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: theme.cardColor,
        title: Text('${m.nickname} 신고', style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: theme.textTheme.bodyLarge?.color),
          decoration: InputDecoration(
            hintText: '신고 사유 (선택)',
            hintStyle: TextStyle(color: theme.textTheme.bodyMedium?.color),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('취소', style: TextStyle(color: theme.textTheme.bodyMedium?.color))),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text('신고', style: TextStyle(color: theme.primaryColor)),
          ),
        ],
      ),
    );
    if (reason == null) return;
    try {
      await ref.read(groupRepoProvider).reportUser(m.id, reason: reason);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('신고가 접수됐어요.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('신고 실패: $e')));
      }
    }
  }

  Future<void> _blockMember(GroupMember m) async {
    final theme = Theme.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: theme.cardColor,
        title: Text('${m.nickname} 차단', style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
        content: Text('차단하면 이후 이 사람의 메시지가 보이지 않고, 새 매칭에서도 제외돼요.', style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('취소', style: TextStyle(color: theme.textTheme.bodyMedium?.color))),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('차단', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(groupRepoProvider).blockUser(m.id);
      if (!mounted) return;
      setState(() => _blockedIds.add(m.id));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('차단했어요.')));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('차단 실패: $e')));
      }
    }
  }

  Future<void> _renameGroup() async {
    final theme = Theme.of(context);
    final controller = TextEditingController(text: _groupName);
    final newName = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: theme.cardColor,
        title: Text('방 이름 변경', style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: theme.textTheme.bodyLarge?.color),
          decoration: InputDecoration(
            hintText: '새 이름',
            hintStyle: TextStyle(color: theme.textTheme.bodyMedium?.color),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('취소', style: TextStyle(color: theme.textTheme.bodyMedium?.color))),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text('변경', style: TextStyle(color: theme.primaryColor)),
          ),
        ],
      ),
    );
    if (newName == null || newName.isEmpty) return;
    try {
      await ref.read(groupRepoProvider).updateGroupName(widget.groupId, newName);
      if (!mounted) return;
      setState(() => _groupName = newName);
      ref.invalidate(myGroupsProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('변경 실패: $e')));
      }
    }
  }

  Future<void> _leaveGroup() async {
    final theme = Theme.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: theme.cardColor,
        title: Text('채팅방 나가기', style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
        content: Text('이 모임에서 나갈까요? 다시 들어올 수 없어요.', style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('취소', style: TextStyle(color: theme.textTheme.bodyMedium?.color))),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('나가기', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(groupRepoProvider).leaveGroup(widget.groupId);
      if (!mounted) return;
      ref.invalidate(myGroupsProvider);
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('나가기 실패: $e')));
      }
    }
  }

  @override
  void dispose() {
    _socket?.emit('leave_room', widget.groupId);
    _socket?.off('new_message', _onNewMessage);
    _socket?.off('reaction_updated', _onReactionUpdated);
    _socket?.off('read_updated', _onReadUpdated);
    _textController.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('$_groupName (${widget.memberCount}명)',
            style: AppTextStyles.title.copyWith(color: theme.textTheme.bodyLarge?.color)),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.person_2_fill),
            onPressed: _showMembers,
          ),
          PopupMenuButton<String>(
            color: theme.cardColor,
            icon: const Icon(CupertinoIcons.ellipsis_vertical),
            onSelected: (v) {
              if (v == 'rename') _renameGroup();
              if (v == 'leave') _leaveGroup();
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'rename', child: Text('방 이름 변경', style: TextStyle(color: theme.textTheme.bodyLarge?.color))),
              PopupMenuItem(value: 'leave', child: Text('채팅방 나가기', style: TextStyle(color: Colors.redAccent))),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                ? Center(
                child: Text('첫 메시지를 보내보세요!',
                    style: AppTextStyles.caption.copyWith(color: theme.textTheme.bodyMedium?.color)))
                : ScrollablePositionedList.builder(
              itemScrollController: _itemScrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, i) {
                final msg = _messages[i];
                final isMine = msg.senderId == _myUserId;
                return _MessageBubble(
                  message: msg,
                  isMine: isMine,
                  myUserId: _myUserId,
                  unreadCount: _unreadCount(msg),
                  highlight: _highlightedId == msg.id,
                  onLongPress: () => _showReactionPicker(msg),
                  onReactionTap: (reaction) =>
                      _toggleReaction(msg.id, reaction),
                  onReply: () => _startReply(msg),
                  onReplyTap: msg.replyTo != null
                      ? () => _scrollToMessage(msg.replyTo!.id)
                      : null,
                );
              },
            ),
          ),
          if (_replyingTo != null) _buildReplyPreview(theme),
          _buildInputBar(theme),
        ],
      ),
    );
  }

  Widget _buildReplyPreview(ThemeData theme) {
    final msg = _replyingTo!;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      color: theme.cardColor,
      child: Row(
        children: [
          Container(
            width: 3,
            height: 36,
            decoration: BoxDecoration(
              color: theme.primaryColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${msg.senderNickname}에게 답장',
                    style: AppTextStyles.caption.copyWith(
                      color: theme.primaryColor,
                      fontWeight: FontWeight.w600,
                    )),
                const SizedBox(height: 2),
                Text(msg.content,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(color: theme.textTheme.bodyMedium?.color)),
              ],
            ),
          ),
          IconButton(
            icon: Icon(CupertinoIcons.xmark, size: 18, color: theme.textTheme.bodyMedium?.color),
            onPressed: () => setState(() => _replyingTo = null),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(ThemeData theme) {
    return SafeArea(
      child: Container(
        color: theme.scaffoldBackgroundColor,
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                focusNode: _inputFocus,
                style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                decoration: InputDecoration(
                  hintText: '메시지 입력하기...',
                  hintStyle: TextStyle(color: theme.textTheme.bodyMedium?.color),
                  filled: true,
                  fillColor: theme.cardColor,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: theme.primaryColor,
              radius: 22,
              child: IconButton(
                onPressed: _sendMessage,
                icon: Icon(CupertinoIcons.paperplane_fill, color: theme.brightness == Brightness.dark ? Colors.black : Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatefulWidget {
  final Message message;
  final bool isMine;
  final int? myUserId;
  final bool highlight;
  final VoidCallback onLongPress;
  final void Function(String reaction) onReactionTap;
  final VoidCallback onReply;
  final VoidCallback? onReplyTap;
  final int unreadCount;

  const _MessageBubble({
    super.key,
    required this.message,
    required this.isMine,
    required this.myUserId,
    required this.highlight,
    required this.onLongPress,
    required this.onReactionTap,
    required this.onReply,
    required this.unreadCount,
    this.onReplyTap,
  });

  @override
  State<_MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<_MessageBubble> {
  double _dragExtent = 0;
  static const double _maxDrag = 70;
  static const double _triggerDrag = 50;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final message = widget.message;

    return GestureDetector(
      onHorizontalDragUpdate: (d) {
        setState(() {
          _dragExtent = (_dragExtent + d.delta.dx).clamp(-_maxDrag, 0.0);
        });
      },
      onHorizontalDragEnd: (_) {
        if (_dragExtent.abs() >= _triggerDrag) {
          widget.onReply();
        }
        setState(() => _dragExtent = 0);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: widget.highlight
              ? theme.primaryColor.withOpacity(0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: Opacity(
                    opacity: (_dragExtent.abs() / _triggerDrag).clamp(0.0, 1.0),
                    child: Icon(CupertinoIcons.reply,
                        color: theme.primaryColor, size: 22),
                  ),
                ),
              ),
            ),
            Transform.translate(
              offset: Offset(_dragExtent, 0),
              child: _buildContent(context, message, widget.isMine, widget.myUserId, theme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
      BuildContext context, Message message, bool isMine, int? myUserId, ThemeData theme) {

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
        isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMine) ...[
            ProfileAvatar(imageId: message.senderProfileImg, radius: 16),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
              isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMine)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2, left: 4),
                    child: Text(message.senderNickname,
                        style: AppTextStyles.caption.copyWith(color: theme.textTheme.bodyLarge?.color)),
                  ),
                if (message.replyTo != null)
                  GestureDetector(
                    onTap: widget.onReplyTap,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 3),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.6),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border(
                            left: BorderSide(color: theme.primaryColor, width: 3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(message.replyTo!.senderNickname,
                              style: AppTextStyles.caption.copyWith(
                                color: theme.primaryColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              )),
                          Text(message.replyTo!.content,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.caption
                                  .copyWith(fontSize: 11, color: theme.textTheme.bodyMedium?.color)),
                        ],
                      ),
                    ),
                  ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (isMine && widget.unreadCount > 0) ...[
                      Text('${widget.unreadCount}',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold,
                              color: Colors.amber.shade600)),
                      const SizedBox(width: 4),
                    ],
                    Flexible(
                      child: GestureDetector(
                        onLongPress: widget.onLongPress,
                        child: Container(
                          constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.65),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isMine ? theme.primaryColor : theme.cardColor,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Text(
                            message.content,
                            style: AppTextStyles.body.copyWith(
                              color: isMine
                                  ? (theme.brightness == Brightness.dark ? Colors.black : Colors.white)
                                  : theme.textTheme.bodyLarge?.color,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (!isMine && widget.unreadCount > 0) ...[
                      const SizedBox(width: 4),
                      Text('${widget.unreadCount}',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold,
                              color: Colors.amber.shade600)),
                    ],
                  ],
                ),   // ← 이 콤마 꼭! 바로 밑 if(reactions)랑 이어지는 거라 없으면 에러
                if (message.reactions.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: message.reactions.map((r) {
                        final reacted = myUserId != null &&
                            r.userIds.contains(myUserId);
                        return GestureDetector(
                          onTap: () => widget.onReactionTap(r.reaction),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: reacted
                                  ? theme.primaryColor.withOpacity(0.15)
                                  : theme.cardColor,
                              borderRadius: BorderRadius.circular(12),
                              border: reacted
                                  ? Border.all(color: theme.primaryColor, width: 1)
                                  : Border.all(color: theme.dividerColor, width: 0.5),
                            ),
                            child: Text('${r.reaction} ${r.count}',
                                style: TextStyle(fontSize: 12, color: theme.textTheme.bodyLarge?.color)),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}