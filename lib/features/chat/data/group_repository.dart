import '../../../core/network/api_client.dart';

class GroupSummary {
  final int id;
  final String name;
  final String status;
  final int memberCount;
  final String? lastMessage;

  GroupSummary({
    required this.id,
    required this.name,
    required this.status,
    required this.memberCount,
    this.lastMessage,
  });

  factory GroupSummary.fromJson(Map<String, dynamic> json) => GroupSummary(
    id: json['id'] as int,
    name: json['name'] as String? ?? '모임',
    status: json['status'] as String? ?? 'active',
    memberCount: json['member_count'] as int? ?? 0,
    lastMessage: json['last_message'] as String?,
  );
}

class GroupRepository {
  Future<List<GroupSummary>> getMyGroups() async {
    final res = await ApiClient.dio.get('/api/groups');
    return (res.data as List)
        .map((e) => GroupSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<int> joinMatching() async {
    final res = await ApiClient.dio.post('/api/matching/join');
    return res.data['groupId'] as int;
  }
}