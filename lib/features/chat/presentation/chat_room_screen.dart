import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../../../core/network/socket_client.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/message_repository.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

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
  final _scrollController = ScrollController();

  final List<Message> _messages = [];
  io.Socket? _socket;
  int? _myUserId;
  bool _isLoading = true;

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
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty || _socket == null) return;
    _socket!.emit('send_message', {
      'groupId': widget.groupId,
      'content': text,
    });
    _textController.clear();
  }

  void _onNewMessage(dynamic data) {
    final msg = Message.fromJson(Map<String, dynamic>.from(data));
    setState(() => _messages.add(msg));
    _scrollToBottom();
  }

  void _onReactionUpdated(dynamic data) {
    debugPrint('### reaction_updated 수신: $data');
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
    _scrollController.dispose();
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
                : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, i) {
                final msg = _messages[i];
                final isMine = msg.senderId == _myUserId;
                return _MessageBubble(
                  message: msg,
                  isMine: isMine,
                  myUserId: _myUserId,
                  onLongPress: () => _showReactionPicker(msg),
                  onReactionTap: (reaction) =>
                      _toggleReaction(msg.id, reaction),
                );
              },
            ),
          ),
          _buildInputBar(),
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

class _MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMine;
  final int? myUserId;
  final VoidCallback onLongPress;
  final void Function(String reaction) onReactionTap;

  const _MessageBubble({
    required this.message,
    required this.isMine,
    required this.myUserId,
    required this.onLongPress,
    required this.onReactionTap,
  });

  @override
  Widget build(BuildContext context) {
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
                GestureDetector(
                  onLongPress: onLongPress,
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
                          onTap: () => onReactionTap(r.reaction),
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