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

  Future<GroupDetail> getGroupDetail(int groupId) async {
    final res = await ApiClient.dio.get('/api/groups/$groupId');
    return GroupDetail.fromJson(Map<String, dynamic>.from(res.data));
  }

  Future<String> updateGroupName(int groupId, String name) async {
    final res = await ApiClient.dio.put('/api/groups/$groupId', data: {'name': name});
    return res.data['name'] as String? ?? name;
  }

  Future<void> leaveGroup(int groupId) async {
    await ApiClient.dio.delete('/api/groups/$groupId/leave');
  }

  // 대기열 등록 → 'waiting'
  Future<String> joinMatching({double threshold = 0.85}) async {
    final res = await ApiClient.dio.post('/api/matching/join', data: {
      'threshold': threshold,
    });
    return res.data['status'] as String? ?? 'waiting';
  }

  // 대기 상태 조회 → 'waiting' | 'idle'
  Future<String> getMatchingStatus() async {
    final res = await ApiClient.dio.get('/api/matching/status');
    return res.data['status'] as String? ?? 'idle';
  }

  // 대기 취소
  Future<void> cancelMatching() async {
    await ApiClient.dio.delete('/api/matching');
  }

  Future<void> reportUser(int targetId, {String? reason}) async {
    await ApiClient.dio.post('/api/users/report',
        data: {'target_id': targetId, 'reason': reason});
  }

  Future<void> blockUser(int targetId) async {
    await ApiClient.dio.post('/api/users/block', data: {'target_id': targetId});
  }

  Future<void> unblockUser(int targetId) async {
    await ApiClient.dio.delete('/api/users/block/$targetId');
  }

  Future<List<GroupMember>> getBlockedUsers() async {
    final res = await ApiClient.dio.get('/api/users/blocks');
    return (res.data as List)
        .map((e) => GroupMember.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}

class GroupMember {
  final int id;
  final String nickname;
  final String? profileImg;
  GroupMember({required this.id, required this.nickname, this.profileImg});
  factory GroupMember.fromJson(Map<String, dynamic> j) => GroupMember(
    id: j['id'] as int,
    nickname: j['nickname'] as String? ?? '',
    profileImg: j['profile_img'] as String?,
  );
}

class GroupDetail {
  final int id;
  final String name;
  final List<GroupMember> members;
  GroupDetail({required this.id, required this.name, required this.members});
  factory GroupDetail.fromJson(Map<String, dynamic> j) => GroupDetail(
    id: j['id'] as int,
    name: j['name'] as String? ?? '모임',
    members: (j['members'] as List? ?? [])
        .map((e) => GroupMember.fromJson(Map<String, dynamic>.from(e)))
        .toList(),
  );
}