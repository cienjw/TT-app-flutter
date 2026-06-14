import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_button.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('프로필 설정'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '환영합니다!\n당신에 대해 알려주세요',
              style: AppTextStyles.headline2,
            ),
            const SizedBox(height: 12),
            Text(
              '관심사를 기반으로 딱 맞는 친구들을\n연결해 드릴게요.',
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: 48),
            
            // Placeholder for interest selection
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.interests_rounded, size: 80, color: AppColors.primaryBlue.withOpacity(0.2)),
                    const SizedBox(height: 24),
                    const Text('관심사 선택 화면 준비 중...', style: AppTextStyles.caption),
                  ],
                ),
              ),
            ),
            
            AppButton(
              label: '시작하기',
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
