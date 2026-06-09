import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'core/storage/secure_storage.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/main/presentation/main_screen.dart';

class MeetoryApp extends StatelessWidget {
  const MeetoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Meetory',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      scrollBehavior: const ScrollBehavior().copyWith(
        overscroll: false,
        physics: const ClampingScrollPhysics(),
      ),
      home: const _StartRouter(),
    );
  }
}

class _StartRouter extends StatelessWidget {
  const _StartRouter();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_AuthState>(
      future: _checkAuth(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          // 스플래시 대신 흰 화면 (나중에 스플래시 추가 가능)
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return switch (snapshot.data!) {
          _AuthState.loggedIn   => const MainScreen(),
          _AuthState.loggedOut  => const LoginScreen(),
        };
      },
    );
  }

  Future<_AuthState> _checkAuth() async {
    final token = await SecureStorage.getAccessToken();
    if (token == null) return _AuthState.loggedOut;

    // 온보딩 완료 여부 확인
    final done = await SecureStorage.isOnboardingComplete();
    if (!done) return _AuthState.loggedOut; // 온보딩 미완료면 로그인부터 다시
    return _AuthState.loggedIn;
  }
}

enum _AuthState { loggedIn, loggedOut }