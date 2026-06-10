import '../../../core/network/api_client.dart';

class UserProfile {
  final int id;
  final String nickname;
  final String? profileImg;
  final String? bio;
  final List<String> interests;

  UserProfile({
    required this.id,
    required this.nickname,
    this.profileImg,
    this.bio,
    required this.interests,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    // interests는 JSON_ARRAYAGG 결과 → [{id, name, category}, ...] 또는 [null]
    final rawInterests = json['interests'] as List?;
    final names = <String>[];
    if (rawInterests != null) {
      for (final item in rawInterests) {
        if (item is Map && item['name'] != null) {
          names.add(item['name'] as String);
        }
      }
    }
    return UserProfile(
      id: json['id'] as int,
      nickname: json['nickname'] as String? ?? '익명',
      profileImg: json['profile_img'] as String?,
      bio: json['bio'] as String?,
      interests: names,
    );
  }
}

class ProfileRepository {
  Future<UserProfile> getMe() async {
    final res = await ApiClient.dio.get('/api/users/me');
    return UserProfile.fromJson(res.data as Map<String, dynamic>);
  }
}