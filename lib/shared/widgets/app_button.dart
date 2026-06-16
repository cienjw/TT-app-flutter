import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

enum AppButtonVariant { filled, outlined, kakao, google }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final AppButtonVariant variant;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.variant = AppButtonVariant.filled,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: switch (variant) {
        AppButtonVariant.kakao => ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.kakaoYellow,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          onPressed: isLoading ? null : onPressed,
          child: _child(Colors.black),
        ),

        AppButtonVariant.google => OutlinedButton(
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: AppColors.meetorySkyBlue.withOpacity(0.3)),
          ),
          onPressed: isLoading ? null : onPressed,
          child: _child(AppColors.meetorySkyBlue),
        ),

        AppButtonVariant.outlined => OutlinedButton(
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: AppColors.meetorySkyBlue.withOpacity(0.5)),
          ),
          onPressed: isLoading ? null : onPressed,
          child: _child(AppColors.meetorySkyBlue),
        ),

        AppButtonVariant.filled => FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.meetorySkyBlue,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          onPressed: isLoading ? null : onPressed,
          child: _child(Colors.white),
        ),
      },
    );
  }

  Widget _child(Color color) {
    if (isLoading) {
      return SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: color,
        ),
      );
    }

    return Text(
      label,
      style: AppTextStyles.button.copyWith(color: color),
    );
  }
}