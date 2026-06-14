import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_button.dart';
import 'survey_questions_screen.dart';

class SurveyIntroScreen extends StatelessWidget {
  const SurveyIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              Text('나와 잘 맞는 사람을\n만나기 위한 첫걸음',
                  style: AppTextStyles.headline1),
              const SizedBox(height: 12),
              Text('나의 관심사와 성향을 알려주시면\n더 정확한 매칭을 도와드릴게요!',
                  style: AppTextStyles.body
                      .copyWith(color: context.cs.onSurfaceVariant, height: 1.5)),
              const SizedBox(height: 40),
              Center(
                child: Container(
                  width: 140, height: 140,
                  decoration: BoxDecoration(
                    color: context.cs.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(CupertinoIcons.smiley,
                      size: 72, color: context.cs.onSurfaceVariant),
                ),
              ),
              const SizedBox(height: 40),
              Row(
                children: [
                  Expanded(child: _infoBox(context, '총 10문항', '약 3분 소요')),
                  const SizedBox(width: 12),
                  Expanded(child: _infoBox(context, '마지막 단계', 'MBTI 입력')),
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
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoBox(BuildContext context, String top, String bottom) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: context.cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(top, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(bottom, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}