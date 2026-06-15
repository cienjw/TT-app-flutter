import 'package:flutter/material.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_button.dart';
import '../../main/presentation/main_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 3),
              Container(
                width: 120, height: 120,
                decoration: BoxDecoration(
                  color: AppColors.backgroundBlue,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryBlue.withOpacity(0.1),
                      blurRadius: 20,
                      spreadRadius: 5,
                    )
                  ],
                ),
                child: const Icon(
                  Icons.celebration_rounded,
                  color: AppColors.primaryBlue,
                  size: 64,
                ),
              ),
              const SizedBox(height: 48),
              const Text(
                'Meetory에\n오신 것을 환영해요!',
                textAlign: TextAlign.center,
                style: AppTextStyles.headline2,
              ),
              const SizedBox(height: 16),
              Text(
                '이제 새로운 인연들과\n즐거운 대화를 시작해볼까요?',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
              ),
              const Spacer(flex: 4),
              AppButton(
                label: 'Meetory 시작하기',
                onPressed: () async {
                  await SecureStorage.setOnboardingComplete();
                  if (!context.mounted) return;
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const MainScreen()),
                        (route) => false,
                  );
                },
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
