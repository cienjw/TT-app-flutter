import '../../../core/network/api_client.dart';

class Message {
  final int id;
  final int senderId;
  final String senderNickname;
  final String? senderProfileImg;
  final String content;
  final DateTime createdAt;

  Message({
    required this.id,
    required this.senderId,
    required this.senderNickname,
    this.senderProfileImg,
    required this.content,
    required this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) => Message(
    id: json['id'] as int,
    senderId: json['sender_id'] as int,
    senderNickname: json['sender_nickname'] as String? ?? '익명',
    senderProfileImg: json['sender_profile_img'] as String?,
    content: json['content'] as String,
    createdAt: DateTime.parse(json['created_at'] as String),
  );
}

class MessageRepository {
  Future<List<Message>> getMessages(int groupId) async {
    final res = await ApiClient.dio.get('/api/groups/$groupId/messages');
    return (res.data as List)
        .map((e) => Message.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}