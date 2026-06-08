import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_storage.dart';

class AuthRepository {
  Future<({String accessToken, String refreshToken, bool isNewUser, int userId})>
  loginWithKakao(String accessToken) async {
    final res = await ApiClient.dio.post('/api/auth/kakao', data: {
      'access_token': accessToken,
    });
    return (
    accessToken:  res.data['accessToken']  as String,
    refreshToken: res.data['refreshToken'] as String,
    isNewUser:    res.data['isNewUser']     as bool,
    userId:       res.data['userId']        as int,
    );
  }

  Future<({String accessToken, String refreshToken, bool isNewUser, int userId})>
  loginWithGoogle(String idToken) async {
    final res = await ApiClient.dio.post('/api/auth/google', data: {
      'id_token': idToken,
    });
    return (
    accessToken:  res.data['accessToken']  as String,
    refreshToken: res.data['refreshToken'] as String,
    isNewUser:    res.data['isNewUser']     as bool,
    userId:       res.data['userId']        as int,
    );
  }

  Future<void> saveTokens(String access, String refresh) async {
    await SecureStorage.saveTokens(
      accessToken: access,
      refreshToken: refresh,
    );
  }

  Future<({String accessToken, String refreshToken, bool isNewUser, int userId})>
  loginWithDev(String nickname) async {
    final res = await ApiClient.dio.post('/api/auth/dev-login', data: {
      'nickname': nickname,
    });
    return (
    accessToken:  res.data['accessToken']  as String,
    refreshToken: res.data['refreshToken'] as String,
    isNewUser:    res.data['isNewUser'] ?? false,
    userId:       res.data['userId']        as int,
    );
  }
}