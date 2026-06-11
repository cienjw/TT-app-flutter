import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // 1. 내 userId 추출 (JWT 디코딩)
    final token = await SecureStorage.getAccessToken();
    if (token != null) {
      final decoded = JwtDecoder.decode(token);
      final raw = decoded['userId'];
      // int든 double이든 String이든 안전하게 int로 변환
      _myUserId = switch (raw) {
        int v => v,
        double v => v.toInt(),
        String v => int.tryParse(v),
        _ => null,
      };
      debugPrint('### my userId from JWT: $_myUserId');  // 디버깅용
    }

    // 2. 과거 메시지 로드
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

    // 3. 소켓 연결 + 방 입장
    _socket = await SocketClient.connect();
    _socket!.emit('join_room', widget.groupId);

    // 4. 새 메시지 수신 리스너
    _socket!.on('new_message', _onNewMessage);
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

  // 1. 핸들러를 별도 함수로 분리
  void _onNewMessage(dynamic data) {
    final msg = Message.fromJson(Map<String, dynamic>.from(data));
    setState(() => _messages.add(msg));
    _scrollToBottom();
  }

  @override
  void dispose() {
    _socket?.emit('leave_room', widget.groupId);
    _socket?.off('new_message', _onNewMessage);
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
                return _MessageBubble(message: msg, isMine: isMine);
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
              icon: const Icon(Icons.send),
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

  const _MessageBubble({required this.message, required this.isMine});

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
              child: Icon(Icons.person, size: 18, color: AppColors.primary),
            ),
            const SizedBox(width: 8),
          ],
          Column(
            crossAxisAlignment:
            isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (!isMine)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2, left: 4),
                  child: Text(message.senderNickname,
                      style: AppTextStyles.caption),
                ),
              Container(
                constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.65),
                padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isMine ? AppColors.primary : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  message.content,
                  style: AppTextStyles.body.copyWith(
                    color: isMine ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}