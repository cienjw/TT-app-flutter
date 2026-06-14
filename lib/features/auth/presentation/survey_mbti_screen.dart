import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/survey_data.dart';
import 'survey_result_screen.dart';
import '../../../shared/widgets/app_button.dart';

class SurveyMbtiScreen extends StatefulWidget {
  final List<SurveyOption> answers;
  const SurveyMbtiScreen({super.key, required this.answers});

  @override
  State<SurveyMbtiScreen> createState() => _SurveyMbtiScreenState();
}

class _SurveyMbtiScreenState extends State<SurveyMbtiScreen> {
  static const _axes = [['E', 'I'], ['S', 'N'], ['T', 'F'], ['J', 'P']];
  final List<String?> _picked = [null, null, null, null];

  bool get _complete => _picked.every((e) => e != null);
  String? get _mbti => _complete ? _picked.join() : null;

  void _finish({required bool skip}) {
    final result = scoreSurvey(widget.answers, mbti: skip ? null : _mbti);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SurveyResultScreen(result: result)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Text(
                '거의 다 왔어요!\n마지막으로 MBTI를 알려주세요',
                style: AppTextStyles.headline2,
              ),
              const SizedBox(height: 12),
              Text(
                '성향을 파악해 더 잘 맞는 대화 상대를\n추천해 드릴게요.',
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: 48),
              
              ...List.generate(_axes.length, (ai) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    children: _axes[ai].map((letter) {
                      final selected = _picked[ai] == letter;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: GestureDetector(
                            onTap: () => setState(() => _picked[ai] = letter),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              height: 64,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: selected ? AppColors.primaryPink : AppColors.lightGrey,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: selected ? AppColors.primaryPink : Colors.transparent,
                                  width: 2,
                                ),
                                boxShadow: selected ? [
                                  BoxShadow(
                                    color: AppColors.primaryPink.withOpacity(0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  )
                                ] : [],
                              ),
                              child: Text(
                                letter,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: selected ? Colors.white : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                );
              }),
              
              const Spacer(),
              AppButton(
                label: '완료하기',
                onPressed: _complete ? () => _finish(skip: false) : null,
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () => _finish(skip: true),
                  child: Text(
                    'MBTI를 모르신다면 건너뛰어도 괜찮아요!',
                    style: AppTextStyles.caption.copyWith(decoration: TextDecoration.underline),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
