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
            elevation: 0,
          ),
          onPressed: isLoading ? null : onPressed,
          child: _buildChild(context, Colors.black),
        ),

        AppButtonVariant.google => OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            side: BorderSide(
              color: context.cs.onSurface.withOpacity(0.15),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: _buildChild(context, context.cs.onSurface),
        ),

        AppButtonVariant.outlined => OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            side: BorderSide(
              color: AppColors.meetorySkyBlue.withOpacity(0.45),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: _buildChild(context, AppColors.meetorySkyBlue),
        ),

        AppButtonVariant.filled => FilledButton(
          onPressed: isLoading ? null : onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.meetorySkyBlue,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: _buildChild(context, Colors.white),
        ),
      },
    );
  }

  Widget _buildChild(BuildContext context, Color color) {
    return isLoading
        ? SizedBox(
      width: 18,
      height: 18,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: color,
      ),
    )
        : Text(label, style: AppTextStyles.button.copyWith(color: color));
  }
}