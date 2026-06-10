import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/profile_repository.dart';

final profileRepoProvider = Provider((_) => ProfileRepository());

final myProfileProvider = FutureProvider<UserProfile>((ref) async {
  return ref.read(profileRepoProvider).getMe();
});