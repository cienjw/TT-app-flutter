import '../../../core/network/api_client.dart';

class UserProfile {
  final int id;
  final String nickname;
  final String? profileImg;
  final String? bio;
  final List<String> interests;
  final double? surveyDepth;
  final double? surveyVirtuality;
  final String? surveyCollab;
  final String? surveyPurpose;
  final String? mbti;

  UserProfile({
    required this.id,
    required this.nickname,
    this.profileImg,
    this.bio,
    required this.interests,
    this.surveyDepth,
    this.surveyVirtuality,
    this.surveyCollab,
    this.surveyPurpose,
    this.mbti,
  });

  // 설문 결과 유형 라벨 (설문 안 했으면 null)
  String? get typeLabel {
    final d = surveyDepth;
    if (d == null) return null;
    final depthWord =
    d >= 0.6 ? '깊이 파고드는' : d <= 0.34 ? '폭넓게 즐기는' : '균형 잡힌';
    final v = surveyVirtuality;
    final virtWord =
    v == null ? '' : v >= 0.6 ? '디지털' : v <= 0.4 ? '아날로그' : '';
    return [depthWord, virtWord, '탐험가'].where((e) => e.isNotEmpty).join(' ');
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final rawInterests = json['interests'] as List?;
    final names = <String>[];
    if (rawInterests != null) {
      for (final item in rawInterests) {
        if (item is Map && item['name'] != null) {
          names.add(item['name'] as String);
        }
      }
    }
    // mysql2가 DECIMAL을 문자열로 줄 수 있어서 둘 다 처리
    double? toD(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v);
      return null;
    }

    return UserProfile(
      id: json['id'] as int,
      nickname: json['nickname'] as String? ?? '익명',
      profileImg: json['profile_img'] as String?,
      bio: json['bio'] as String?,
      interests: names,
      surveyDepth: toD(json['survey_depth']),
      surveyVirtuality: toD(json['survey_virtuality']),
      surveyCollab: json['survey_collab'] as String?,
      surveyPurpose: json['survey_purpose'] as String?,
      mbti: json['mbti'] as String?,
    );
  }
}

class ProfileRepository {
  Future<UserProfile> getMe() async {
    final res = await ApiClient.dio.get('/api/users/me');
    return UserProfile.fromJson(res.data as Map<String, dynamic>);
  }
}