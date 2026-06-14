import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_button.dart';
import 'survey_questions_screen.dart';

class SurveyIntroScreen extends StatelessWidget {
  const SurveyIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.backgroundBlue.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.favorite_rounded,
                  size: 80,
                  color: AppColors.primaryPink,
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                '나와 잘 맞는 사람을\n만나기 위한 첫걸음',
                textAlign: TextAlign.center,
                style: AppTextStyles.headline2,
              ),
              const SizedBox(height: 16),
              Text(
                '나의 관심사와 성향을 알려주시면\n더 정확한 매칭을 도와드릴게요!',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall.copyWith(height: 1.6),
              ),
              const SizedBox(height: 48),
              
              Row(
                children: [
                  Expanded(child: _infoBox('총 10문항', '약 3분 소요', Icons.timer_outlined)),
                  const SizedBox(width: 16),
                  Expanded(child: _infoBox('마지막 단계', 'MBTI 입력', Icons.psychology_outlined)),
                ],
              ),
              
              const Spacer(),
              AppButton(
                label: '테스트 시작하기',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const SurveyQuestionsScreen()),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoBox(String top, String bottom, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.lightGrey,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryBlue.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primaryBlue, size: 24),
          const SizedBox(height: 12),
          Text(top, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 4),
          Text(bottom, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}
