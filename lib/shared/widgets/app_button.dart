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
            foregroundColor: Colors.black87,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
          onPressed: isLoading ? null : onPressed,
          child: _buildChild(color: Colors.black87),
        ),
        AppButtonVariant.google => OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          child: _buildChild(),
        ),
        AppButtonVariant.outlined => OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          child: _buildChild(),
        ),
        AppButtonVariant.filled => FilledButton(
          onPressed: isLoading ? null : onPressed,
          child: _buildChild(),
        ),
      },
    );
  }

  Widget _buildChild({Color? color}) => isLoading
      ? SizedBox(
      width: 20, height: 20,
      child: CircularProgressIndicator(
          strokeWidth: 2,
          color: color ?? Colors.white))
      : Text(label,
      style: AppTextStyles.button.copyWith(color: color));
}