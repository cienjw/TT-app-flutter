import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_button.dart';
import '../../main/presentation/main_screen.dart';
import '../data/survey_data.dart';

class SurveyResultScreen extends StatelessWidget {
  final SurveyResult result;
  const SurveyResultScreen({super.key, required this.result});

  Future<void> _start(BuildContext context) async {
    try {
      await ApiClient.dio.put('/api/users/me/survey', data: {
        'fields': result.fields.map((f) => f.name).toList(),
        'depth': result.depth,
        'virtuality': result.virtuality,
        'collab': result.collab.name,
        'purpose': result.purpose.name,
        'mbti': result.mbti,
      });
    } catch (_) {}
    await SecureStorage.setOnboardingComplete();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const MainScreen()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppColors.backgroundBlue.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  size: 80,
                  color: AppColors.primaryBlue,
                ),
              ),
              const SizedBox(height: 40),
              Text(
                '분석 완료!',
                style: AppTextStyles.body.copyWith(color: AppColors.primaryPink, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                '당신은 어떤 사람일까요?',
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: 12),
              Text(
                surveyTypeName(result),
                textAlign: TextAlign.center,
                style: AppTextStyles.headline2.copyWith(fontSize: 28),
              ),
              const SizedBox(height: 32),
              
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: result.fields.map((f) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.lightGrey,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primaryBlue.withOpacity(0.1)),
                    ),
                    child: Text(
                      f.label,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                  );
                }).toList(),
              ),
              
              if (result.mbti != null) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryPink,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    result.mbti!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ],
              
              const Spacer(),
              AppButton(
                label: 'Meetory 시작하기',
                onPressed: () => _start(context),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
