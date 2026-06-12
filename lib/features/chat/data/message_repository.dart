import '../../../core/network/api_client.dart';

class MessageReaction {
  final String reaction;
  final int count;
  final List<int> userIds;

  MessageReaction({
    required this.reaction,
    required this.count,
    required this.userIds,
  });

  factory MessageReaction.fromJson(Map<String, dynamic> json) => MessageReaction(
    reaction: json['reaction'] as String,
    count: (json['count'] as num).toInt(),
    userIds: (json['userIds'] as List?)
        ?.map((e) => (e as num).toInt())
        .toList() ?? [],
  );
}

class Message {
  final int id;
  final int senderId;
  final String senderNickname;
  final String? senderProfileImg;
  final String content;
  final DateTime createdAt;
  final List<MessageReaction> reactions;

  Message({
    required this.id,
    required this.senderId,
    required this.senderNickname,
    this.senderProfileImg,
    required this.content,
    required this.createdAt,
    this.reactions = const [],
  });

  Message copyWith({List<MessageReaction>? reactions}) => Message(
    id: id,
    senderId: senderId,
    senderNickname: senderNickname,
    senderProfileImg: senderProfileImg,
    content: content,
    createdAt: createdAt,
    reactions: reactions ?? this.reactions,
  );

  factory Message.fromJson(Map<String, dynamic> json) => Message(
    id: json['id'] as int,
    senderId: json['sender_id'] as int,
    senderNickname: json['sender_nickname'] as String? ?? '익명',
    senderProfileImg: json['sender_profile_img'] as String?,
    content: json['content'] as String,
    createdAt: DateTime.parse(json['created_at'] as String),
    reactions: (json['reactions'] as List?)
        ?.map((e) => MessageReaction.fromJson(Map<String, dynamic>.from(e)))
        .toList() ?? [],
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