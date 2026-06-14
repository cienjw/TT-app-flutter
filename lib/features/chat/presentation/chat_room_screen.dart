import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../../../core/network/socket_client.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/message_repository.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/group_repository.dart';
import '../domain/chat_provider.dart';

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

    _socket = await SocketClient.connect();
    _socket!.emit('join_room', widget.groupId);
    _socket!.on('new_message', _onNewMessage);
    _socket!.on('reaction_updated', _onReactionUpdated);
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
    setState(() => _messages.add(msg));
    _scrollToBottom();
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
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.lightGrey,
                    shape: BoxShape.circle,
                  ),
                  child: Text(emoji, style: const TextStyle(fontSize: 32)),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Future<void> _showMembers() async {
    try {
      final detail = await ref.read(groupRepoProvider).getGroupDetail(widget.groupId);
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        builder: (_) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('참여 멤버 ${detail.members.length}명', style: AppTextStyles.title),
                const SizedBox(height: 20),
                ...detail.members.map((m) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(color: AppColors.backgroundBlue, shape: BoxShape.circle),
                        child: const Icon(Icons.person_rounded, size: 24, color: AppColors.primaryBlue),
                      ),
                      const SizedBox(width: 16),
                      Text(m.nickname, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                )),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('멤버를 불러오지 못했어요: $e'), backgroundColor: AppColors.error));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Column(
          children: [
            Text(_groupName, style: AppTextStyles.title.copyWith(fontSize: 16)),
            Text('${widget.memberCount}명 참여 중', style: AppTextStyles.caption.copyWith(fontSize: 12)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.people_alt_rounded),
            onPressed: _showMembers,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.chat_bubble_outline_rounded, size: 48, color: AppColors.textHint.withOpacity(0.5)),
                    const SizedBox(height: 16),
                    Text('첫 메시지를 보내보세요!', style: AppTextStyles.caption),
                  ],
                ))
                : ScrollablePositionedList.builder(
              itemScrollController: _itemScrollController,
              padding: const EdgeInsets.all(20),
              itemCount: _messages.length,
              itemBuilder: (context, i) {
                final msg = _messages[i];
                final isMine = msg.senderId == _myUserId;
                return _MessageBubble(
                  message: msg,
                  isMine: isMine,
                  myUserId: _myUserId,
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
          if (_replyingTo != null) _buildReplyPreview(),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildReplyPreview() {
    final msg = _replyingTo!;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.lightGrey,
        border: Border(top: BorderSide(color: Colors.black.withOpacity(0.05))),
      ),
      child: Row(
        children: [
          Container(
            width: 4, height: 32,
            decoration: BoxDecoration(color: AppColors.primaryPink, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${msg.senderNickname}에게 답장', style: const TextStyle(color: AppColors.primaryPink, fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 4),
                Text(msg.content, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.caption),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 20),
            onPressed: () => setState(() => _replyingTo = null),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 8 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              focusNode: _inputFocus,
              decoration: InputDecoration(
                hintText: '메시지를 입력하세요...',
                fillColor: AppColors.lightGrey,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(color: AppColors.primaryPink, shape: BoxShape.circle),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 24),
            ),
          ),
        ],
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

  const _MessageBubble({
    super.key,
    required this.message,
    required this.isMine,
    this.myUserId,
    this.highlight = false,
    required this.onLongPress,
    required this.onReactionTap,
    required this.onReply,
    this.onReplyTap,
  });

  @override
  State<_MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<_MessageBubble> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: widget.isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!widget.isMine) ...[
            Text(widget.message.senderNickname, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(height: 6),
          ],
          GestureDetector(
            onLongPress: widget.onLongPress,
            onDoubleTap: widget.onReply,
            child: Row(
              mainAxisAlignment: widget.isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (widget.isMine) _buildTime(),
                const SizedBox(width: 8),
                Flexible(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: widget.highlight
                          ? AppColors.primaryPink.withOpacity(0.2)
                          : (widget.isMine ? AppColors.primaryPink : AppColors.lightGrey),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(20),
                        topRight: const Radius.circular(20),
                        bottomLeft: Radius.circular(widget.isMine ? 20 : 4),
                        bottomRight: Radius.circular(widget.isMine ? 4 : 20),
                      ),
                      boxShadow: widget.highlight ? [BoxShadow(color: AppColors.primaryPink.withOpacity(0.3), blurRadius: 10)] : [],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.message.replyTo != null) _buildReplyTag(),
                        Text(
                          widget.message.content,
                          style: TextStyle(
                            color: widget.isMine ? Colors.white : AppColors.textPrimary,
                            fontSize: 15,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (!widget.isMine) _buildTime(),
              ],
            ),
          ),
          if (widget.message.reactions.isNotEmpty) _buildReactions(),
        ],
      ),
    );
  }

  Widget _buildTime() {
    final timeStr = DateFormat('a h:mm').format(widget.message.createdAt);
    return Text(timeStr, style: AppTextStyles.caption.copyWith(fontSize: 10));
  }

  Widget _buildReplyTag() {
    return GestureDetector(
      onTap: widget.onReplyTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.reply_rounded, size: 14, color: AppColors.textSecondary),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                '${widget.message.replyTo!.senderNickname}: ${widget.message.replyTo!.content}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReactions() {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(
        spacing: 4,
        children: widget.message.reactions.map((r) {
          final isMyReaction = r.userIds.contains(widget.myUserId);
          return GestureDetector(
            onTap: () => widget.onReactionTap(r.emoji),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isMyReaction ? AppColors.primaryPink.withOpacity(0.1) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isMyReaction ? AppColors.primaryPink : AppColors.lightGrey),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(r.emoji, style: const TextStyle(fontSize: 12)),
                  const SizedBox(width: 4),
                  Text('${r.count}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isMyReaction ? AppColors.primaryPink : AppColors.textSecondary)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
