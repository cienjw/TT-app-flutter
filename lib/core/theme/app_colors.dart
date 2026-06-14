import 'package:flutter/material.dart';

class AppColors {
  // Meetory 로고 기반 메인 색상
  static const primaryPink = Color(0xFFF28A91); // 핑크
  static const primaryBlue = Color(0xFF8CBFD5); // 블루
  static const backgroundBlue = Color(0xFFD4E9EE); // 연한 배경 블루
  static const darkBlue = Color(0xFF2B4C7E); // 로고의 텍스트/라인용 어두운 블루 (추정)

  // 공통 흑백
  static const black = Color(0xFF1A1A1A);
  static const white = Color(0xFFFFFFFF);
  static const grey = Color(0xFF9E9E9E);
  static const lightGrey = Color(0xFFF5F5F5);

  // 시맨틱 색상
  static const primary = primaryPink;
  static const secondary = primaryBlue;
  static const background = white;
  static const surface = white;
  static const error = Color(0xFFE53935);
  static const success = Color(0xFF43A047);

  // 텍스트 색상
  static const textPrimary = Color(0xFF1A1A1A);
  static const textSecondary = Color(0xFF757575);
  static const textHint = Color(0xFFBDBDBD);

  // 소셜 색상
  static const kakaoYellow = Color(0xFFFEE500);
}

extension ColorSchemeX on BuildContext {
  ColorScheme get cs => Theme.of(this).colorScheme;
}
