import 'package:flutter/material.dart';

class AppTextStyles {
  static const headline1 = TextStyle(
    fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: -0.5,
  );
  static const headline2 = TextStyle(
    fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.3,
  );
  static const title = TextStyle(
    fontSize: 18, fontWeight: FontWeight.w600,
  );
  static const body = TextStyle(
    fontSize: 16,
  );
  static const caption = TextStyle(
    fontSize: 13, color: Color(0xFF9CA3AF), // 라이트·다크 둘 다 무난한 회색
  );
  static const button = TextStyle(
    fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.2,
  );
}