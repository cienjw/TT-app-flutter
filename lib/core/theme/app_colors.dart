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

  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFF8F9FA);
  static const Color lightPrimary = Color(0xFF6200EE); // 메인 브랜드 컬러 예시
  static const Color lightTextPrimary = Color(0xFF212121);
  static const Color lightTextSecondary = Color(0xFF757575);
  static const Color lightBorder = Color(0xFFE0E0E0);

  // ===== 다크 테마 =====

  // 기존 검정 → 네이비 기반으로 변경

  static const Color darkBackground = Color(0xFF121212); // 메인 스크롤 배경
  static const Color darkSurface = Color(0xFF1E1E1E);    // 카드, 입력창 등 컴포넌트 배경
  static const Color darkPrimary = Color(0xFFBB86FC);    // 다크모드 대응 브랜드 컬러
  static const Color darkTextPrimary = Color(0xFFF5F5F5);
  static const Color darkTextSecondary = Color(0xFF9E9E9E);
  static const Color darkBorder = Color(0xFF2C2C2C);

  // --- 약관 동의 배경색 (선택 시 연하게 강조되는 색상) ---
  static const Color termsSelectedLight = Color(0xFFE8F0FE); // 라이트모드용 부드러운 블루
  static const Color termsSelectedDark = Color(0xFF1F2B3D);  // 다크모드용 은은한 가시성 블루

  // Status
  static const error           = Color(0xFFE53935);
  static const success         = Color(0xFF43A047);
  static const kakaoYellow     = Color(0xFFFEE500);
}

extension ColorSchemeX on BuildContext {
  ColorScheme get cs => Theme.of(this).colorScheme;
}