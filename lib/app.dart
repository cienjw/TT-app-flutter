import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/login_screen.dart';

class TtApp extends StatelessWidget {
  const TtApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TT',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,  // 다크모드 자동 대응

      // ✅ Android 오버스크롤 글로우 제거
      scrollBehavior: const ScrollBehavior().copyWith(
        overscroll: false,
        physics: const ClampingScrollPhysics(),
      ),

      home: const LoginScreen(),
    );
  }
}