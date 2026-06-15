import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/theme/app_theme.dart';
import 'core/storage/secure_storage.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/main/presentation/main_screen.dart';
import 'core/theme/app_colors.dart';

class MeetoryApp extends StatelessWidget {
  const MeetoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 상태바 색상 설정
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ));

    return MaterialApp(
      title: 'Meetory',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      // Meetory의 브랜드 컬러를 강조하기 위해 라이트 모드를 기본으로 사용합니다.
      themeMode: ThemeMode.light,
      scrollBehavior: const ScrollBehavior().copyWith(
        overscroll: false,
        physics: const BouncingScrollPhysics(),
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
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(child: CircularProgressIndicator(color: AppColors.primaryPink)),
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

    final done = await SecureStorage.isOnboardingComplete();
    if (!done) return _AuthState.loggedOut;
    return _AuthState.loggedIn;
  }
}

enum _AuthState { loggedIn, loggedOut }
