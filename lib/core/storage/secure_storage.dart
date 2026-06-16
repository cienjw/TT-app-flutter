import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static const _storage = FlutterSecureStorage();

  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: 'access_token', value: accessToken);
    await _storage.write(key: 'refresh_token', value: refreshToken);
  }

  static Future<String?> getAccessToken() async {
    return await _storage.read(key: 'access_token');
  }

  static Future<String?> getRefreshToken() async {
    return await _storage.read(key: 'refresh_token');
  }

  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }
  static Future<void> setOnboardingComplete() async {
    await _storage.write(key: 'onboarding_complete', value: 'true');
  }

  static Future<bool> isOnboardingComplete() async {
    return await _storage.read(key: 'onboarding_complete') == 'true';
  }

  static Future<void> setMatchThreshold(double v) =>
      _storage.write(key: 'match_threshold', value: v.toString());

  static Future<double?> getMatchThreshold() async {
    final s = await _storage.read(key: 'match_threshold');
    return s == null ? null : double.tryParse(s);
  }
}

