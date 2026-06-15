import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/survey_data.dart';
import 'survey_result_screen.dart';

class SurveyMbtiScreen extends StatefulWidget {
  final List<SurveyOption> answers;
  final bool isEdit;
  const SurveyMbtiScreen({super.key, required this.answers, this.isEdit = false});

  @override
  State<SurveyMbtiScreen> createState() => _SurveyMbtiScreenState();
}

class _SurveyMbtiScreenState extends State<SurveyMbtiScreen> {
  // 4개 축, 각 축에서 하나 선택
  static const _axes = [['E', 'I'], ['S', 'N'], ['T', 'F'], ['J', 'P']];
  final List<String?> _picked = [null, null, null, null];

  bool get _complete => _picked.every((e) => e != null);
  String? get _mbti => _complete ? _picked.join() : null;

  void _finish({required bool skip}) {
    final result = scoreSurvey(widget.answers, mbti: skip ? null : _mbti);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SurveyResultScreen(result: result, isEdit: widget.isEdit)),
    );
  }

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
              Text('당신의 취향은\n완벽히 파악했어요!',
                  style: AppTextStyles.headline1),
              const SizedBox(height: 12),
              Text('마지막으로, 당신의 MBTI는 무엇인가요?',
                  style: AppTextStyles.body
                      .copyWith(color: context.cs.onSurfaceVariant)),
              const SizedBox(height: 40),
              ...List.generate(_axes.length, (ai) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: _axes[ai].map((letter) {
                      final selected = _picked[ai] == letter;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _picked[ai] = letter),
                            child: Container(
                              height: 56,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: selected
                                    ? context.cs.primary
                                    : context.cs.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(letter,
                                  style: AppTextStyles.headline2.copyWith(
                                    color: selected
                                        ? context.cs.onPrimary
                                        : context.cs.onSurface,
                                  )),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                );
              }),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _complete ? () => _finish(skip: false) : null,
                  child: const Text('완료'),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: () => _finish(skip: true),
                  child: Text('모르신다면 건너뛰어도 괜찮아요!',
                      style: AppTextStyles.caption),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}