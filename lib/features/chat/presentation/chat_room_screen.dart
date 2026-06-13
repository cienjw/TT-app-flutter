import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../../../core/network/socket_client.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/message_repository.dart';


class ChatRoomScreen extends StatefulWidget {
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
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final _repo = MessageRepository();
  final _textController = TextEditingController();
  final _inputFocus = FocusNode();

  final List<Message> _messages = [];
  io.Socket? _socket;
  int? _myUserId;
  bool _isLoading = true;
  Message? _replyingTo;
  int? _highlightedId;
  final _itemScrollController = ItemScrollController();

  static const _reactionEmojis = ['❤️', '👍', '😂', '😮', '😢'];

  @override
  void initState() {
    super.initState();
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

  // 답장 원본 메시지로 스크롤 + 하이라이트
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
      backgroundColor: AppColors.surface,
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

  @override
  void dispose() {
    _socket?.emit('leave_room', widget.groupId);
    _socket?.off('new_message', _onNewMessage);
    _socket?.off('reaction_updated', _onReactionUpdated);
    _textController.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.groupName} (${widget.memberCount}명)',
            style: AppTextStyles.title),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                ? Center(
                child: Text('첫 메시지를 보내보세요!',
                    style: AppTextStyles.caption))
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
                  highlight: _highlightedId == msg.id,
                  onLongPress: () => _showReactionPicker(msg),
                  onReactionTap: (reaction) => _toggleReaction(msg.id, reaction),
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
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      color: AppColors.surfaceVariant,
      child: Row(
        children: [
          Container(
            width: 3,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary,
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
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    )),
                const SizedBox(height: 2),
                Text(msg.content,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(CupertinoIcons.xmark, size: 18),
            onPressed: () => setState(() => _replyingTo = null),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                focusNode: _inputFocus,
                decoration: const InputDecoration(
                  hintText: '메시지 입력하기...',
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: _sendMessage,
              icon: const Icon(CupertinoIcons.paperplane_fill),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.primary,
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

  const _MessageBubble({
    super.key,
    required this.message,
    required this.isMine,
    required this.myUserId,
    required this.highlight,
    required this.onLongPress,
    required this.onReactionTap,
    required this.onReply,
    this.onReplyTap,
  });

  @override
  State<_MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<_MessageBubble> {
  double _dragExtent = 0;
  static const double _maxDrag = 70; // 최대 당김 거리
  static const double _triggerDrag = 50; // 답장 걸리는 임계값

  @override
  Widget build(BuildContext context) {
    final message = widget.message;
    final isMine = widget.isMine;
    final myUserId = widget.myUserId;

    return GestureDetector(
      onHorizontalDragUpdate: (d) {
        setState(() {
          // 왼쪽(음수)으로만, 최대 _maxDrag 까지
          _dragExtent = (_dragExtent + d.delta.dx).clamp(-_maxDrag, 0.0);
        });
      },
      onHorizontalDragEnd: (_) {
        if (_dragExtent.abs() >= _triggerDrag) {
          widget.onReply();
        }
        setState(() => _dragExtent = 0); // 원위치
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: widget.highlight
              ? AppColors.primaryLight.withOpacity(0.4)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            // 당길 때 서서히 나타나는 답장 아이콘
            Positioned.fill(
              child: Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: Opacity(
                    opacity: (_dragExtent.abs() / _triggerDrag).clamp(0.0, 1.0),
                    child: Icon(CupertinoIcons.reply,
                        color: AppColors.primary, size: 22),
                  ),
                ),
              ),
            ),
            Transform.translate(
              offset: Offset(_dragExtent, 0),
              child: _buildContent(context, message, isMine, myUserId),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
      BuildContext context, Message message, bool isMine, int? myUserId) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
        isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMine) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primaryLight,
              child: Icon(CupertinoIcons.person_fill,
                  size: 18, color: AppColors.primary),
            ),
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
                        style: AppTextStyles.caption),
                  ),

                // 이 메시지가 답장이면 → 누르면 원본으로 이동
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
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(10),
                        border: Border(
                            left: BorderSide(
                                color: AppColors.primary, width: 3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(message.replyTo!.senderNickname,
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              )),
                          Text(message.replyTo!.content,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.caption
                                  .copyWith(fontSize: 11)),
                        ],
                      ),
                    ),
                  ),

                GestureDetector(
                  onLongPress: widget.onLongPress,
                  child: Container(
                    constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.65),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isMine
                          ? AppColors.primary
                          : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      message.content,
                      style: AppTextStyles.body.copyWith(
                        color: isMine ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),

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
                                  ? AppColors.primaryLight
                                  : AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(12),
                              border: reacted
                                  ? Border.all(
                                  color: AppColors.primary, width: 1)
                                  : null,
                            ),
                            child: Text('${r.reaction} ${r.count}',
                                style: const TextStyle(fontSize: 12)),
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