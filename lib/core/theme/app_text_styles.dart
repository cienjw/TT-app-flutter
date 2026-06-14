import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  static const headline1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5,
    color: AppColors.textPrimary,
  );
  
  static const headline2 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    color: AppColors.textPrimary,
  );
  
  static const title = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  
  static const body = TextStyle(
    fontSize: 16,
    color: AppColors.textPrimary,
  );
  
  static const bodySmall = TextStyle(
    fontSize: 14,
    color: AppColors.textSecondary,
  );
  
  static const caption = TextStyle(
    fontSize: 13,
    color: AppColors.textHint,
  );
  
  static const button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
    color: Colors.white,
  );
}
