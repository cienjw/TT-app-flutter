import 'package:flutter/material.dart';

class AppColors {
  // 공통 흑백
  static const black = Color(0xFF000000);
  static const white = Color(0xFFFFFFFF);

  // Meetory 공식 색상
  static const meetorySkyBlue = Color(0xFF3A445D); // Twilight Indigo (Press Kit 기반, 실제론 진한 파랑/하늘색 느낌)
  static const meetoryPink = Color(0xFFE06952);    // Burnt Peach (Press Kit 기반, 실제론 핑크/오렌지 느낌)

  // 보조 색상 (하늘색/핑크색의 더 밝은 버전)
  static const skyBlueLight = Color(0xFF82C8E5);
  static const pinkLight = Color(0xFFFF8DA1);

  // 기존 호환 이름 (라이트 기준값)
  static const primary         = meetorySkyBlue;
  static const primaryLight    = Color(0xFFF2F2F2);
  static const secondary       = meetoryPink;
  static const background      = white;
  static const surface         = white;
  static const surfaceVariant  = Color(0xFFF2F2F2);
  static const textPrimary     = black;
  static const textSecondary   = Color(0xFF6B7280);
  static const textHint        = Color(0xFF9CA3AF);

  // 라이트 팔레트
  static const lightBg             = white;
  static const lightSurface        = white;
  static const lightSurfaceVariant = Color(0xFFF2F2F2);
  static const lightTextPrimary    = black;
  static const lightTextSecondary  = Color(0xFF6B7280);
  static const lightTextHint       = Color(0xFF9CA3AF);

  // 다크 팔레트 (#000 기반)
  static const darkBg              = black;
  static const darkSurface         = black;
  static const darkSurfaceVariant  = Color(0xFF1C1C1E);
  static const darkTextPrimary     = white;
  static const darkTextSecondary   = Color(0xFFA1A1AA);
  static const darkTextHint        = Color(0xFF71717A);
  static const darkBackground      = black; // 기존 이름 호환

  // Status
  static const error           = Color(0xFFE53935);
  static const success         = Color(0xFF43A047);
  static const kakaoYellow     = Color(0xFFFEE500);
}

extension ColorSchemeX on BuildContext {
  ColorScheme get cs => Theme.of(this).colorScheme;
}