import 'package:flutter/material.dart';

class AppColors {
  // 공통 흑백
  static const black = Color(0xFF000000);
  static const white = Color(0xFFFFFFFF);

  // Meetory 공식 컬러
  static const meetoryNavy = Color(0xFF3A445D);
  static const meetoryPink = Color(0xFFE06952);
  static const meetorySkyBlue = Color(0xFF9CC7D8);

  // 밝은 버전
  static const navyLight = Color(0xFF55627E);
  static const pinkLight = Color(0xFFFF8DA1);
  static const skyBlueLight = Color(0xFFB8DCE8);

  // 기존 호환 이름
  static const primary = meetorySkyBlue;
  static const primaryLight = Color(0xFFF2F2F2);
  static const secondary = meetoryPink;

  static const background = white;
  static const surface = white;
  static const surfaceVariant = Color(0xFFF2F2F2);

  static const textPrimary = black;
  static const textSecondary = Color(0xFF6B7280);
  static const textHint = Color(0xFF9CA3AF);

  // ===== 라이트 테마 =====

  static const lightBg = white;

  static const lightSurface = white;

  static const lightSurfaceVariant = Color(0xFFF5F6F8);

  static const lightTextPrimary = black;

  static const lightTextSecondary = Color(0xFF6B7280);

  static const lightTextHint = Color(0xFF9CA3AF);

  // ===== 다크 테마 =====

  // 기존 검정 → 네이비 기반으로 변경

  static const darkBg = Color(0xFF14161B); // 순수 검정 → 부드러운 다크
  static const darkSurface         = Color(0xFF1A1D24);
  static const darkSurfaceVariant  = Color(0xFF252830);
  static const darkTextSecondary   = Color(0xFFB8BCC8); // 기존 0xFFA1A1AA보다 밝게
  static const darkTextHint        = Color(0xFF8B909E); // 기존 0xFF71717A보다 밝게

  static const darkTextPrimary = Color(0xFFE9EEF5);

  // 다크 accent (강한 핑크 금지)
  static const darkPrimarySoft = Color(0xFFF2B2A8); // soft coral
  static const darkPrimarySoft2 = Color(0xFFB8DCE8); // soft sky

  // 약관 highlight용 (핵심)
  static const termsSelectedDark = Color(0xFFF2B2A8);

  static const darkBackground = darkBg;


  // Status
  static const error           = Color(0xFFE53935);
  static const success         = Color(0xFF43A047);
  static const kakaoYellow     = Color(0xFFFEE500);
}

extension ColorSchemeX on BuildContext {
  ColorScheme get cs => Theme.of(this).colorScheme;
}