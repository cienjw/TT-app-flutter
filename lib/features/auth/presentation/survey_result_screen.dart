import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_button.dart';
import '../../main/presentation/main_screen.dart';
import '../../chat/domain/chat_provider.dart'; // groupRepoProvider
import '../data/survey_data.dart';

class SurveyResultScreen extends ConsumerWidget {
  final SurveyResult result;
  const SurveyResultScreen({super.key, required this.result});

  Future<void> _start(WidgetRef ref, BuildContext context) async {
    try {
      await ApiClient.dio.put('/api/users/me/survey', data: {
        'fields': result.fields.map((f) => f.name).toList(),
        'depth': result.depth,
        'virtuality': result.virtuality,
        'collab': result.collab.name,
        'purpose': result.purpose.name,
        'mbti': result.mbti,
      });
      // 설문 완료 → 홈 진입과 동시에 자동으로 매칭 대기열 등록
      await ref.read(groupRepoProvider).joinMatching(threshold: 0.3);
    } catch (_) {
      // 발표 데모 중엔 실패해도 흐름은 막지 않음
    }
    await SecureStorage.setOnboardingComplete();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const MainScreen()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 120, height: 120,
                decoration: BoxDecoration(
                  color: context.cs.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: Icon(CupertinoIcons.sparkles,
                    size: 60, color: context.cs.onSurfaceVariant),
              ),
              const SizedBox(height: 28),
              Text('당신은', style: AppTextStyles.body
                  .copyWith(color: context.cs.onSurfaceVariant)),
              const SizedBox(height: 6),
              Text(surveyTypeName(result),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.headline1),
              const SizedBox(height: 24),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: result.fields.map((f) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: context.cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(f.label,
                        style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w600)),
                  );
                }).toList(),
              ),
              if (result.mbti != null) ...[
                const SizedBox(height: 12),
                Text(result.mbti!,
                    style: AppTextStyles.title
                        .copyWith(color: context.cs.primary)),
              ],
              const Spacer(),
              AppButton(label: '시작하기', onPressed: () => _start(ref, context)),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}