import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../data/auth_repository.dart';
import 'dart:io' show Platform;

final authRepoProvider = Provider((_) => AuthRepository());

// 로그인 상태: null=미확인, false=비로그인, true=로그인
class AuthNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async => false;

  Future<bool> loginWithKakao() async {
    state = const AsyncLoading();
    try {
      OAuthToken token;
      // 카카오톡 앱으로 시도 → 실패하면 카카오 계정(웹)으로 폴백
      if (await isKakaoTalkInstalled()) {
        try {
          token = await UserApi.instance.loginWithKakaoTalk();
        } catch (e) {
          // 카카오톡은 있지만 로그인 안 된 경우 등 → 웹 로그인으로
          token = await UserApi.instance.loginWithKakaoAccount();
        }
      } else {
        token = await UserApi.instance.loginWithKakaoAccount();
      }

      final repo = ref.read(authRepoProvider);
      final result = await repo.loginWithKakao(token.accessToken);
      await repo.saveTokens(result.accessToken, result.refreshToken);

      state = const AsyncData(true);
      return result.isNewUser;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<bool> loginWithGoogle() async {
    state = const AsyncLoading();
    try {
      final account = await GoogleSignIn(
        clientId: Platform.isIOS
            ? '28123611250-ji4iut5kenf3v7an9v2sach2q34qreop.apps.googleusercontent.com'
            : null,
        serverClientId: '281236112500-t0ssar7j92mfd4vmkq610f9ku3kl83k3.apps.googleusercontent.com',
      ).signIn();

      if (account == null) {
        state = const AsyncData(false);
        return false;
      }
      final auth = await account.authentication;
      if (auth.idToken == null) throw Exception('idToken을 가져올 수 없습니다');

      final repo = ref.read(authRepoProvider);
      final result = await repo.loginWithGoogle(auth.idToken!);
      await repo.saveTokens(result.accessToken, result.refreshToken);

      state = const AsyncData(true);
      return result.isNewUser;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final authProvider =
AsyncNotifierProvider<AuthNotifier, bool>(AuthNotifier.new);