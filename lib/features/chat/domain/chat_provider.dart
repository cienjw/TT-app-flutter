import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/group_repository.dart';

final groupRepoProvider = Provider((_) => GroupRepository());

// 내 그룹 목록 (FutureProvider — 자동 로딩/에러 처리)
final myGroupsProvider = FutureProvider<List<GroupSummary>>((ref) async {
  return ref.read(groupRepoProvider).getMyGroups();
});