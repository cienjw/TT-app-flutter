import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/survey_data.dart';
import 'survey_mbti_screen.dart';

class SurveyQuestionsScreen extends StatefulWidget {
  const SurveyQuestionsScreen({super.key});

  @override
  State<SurveyQuestionsScreen> createState() => _SurveyQuestionsScreenState();
}

class _SurveyQuestionsScreenState extends State<SurveyQuestionsScreen> {
  final _pageController = PageController();
  final List<SurveyOption?> _answers =
  List.filled(surveyQuestions.length, null);
  int _current = 0;

  void _select(int qIndex, SurveyOption option) {
    setState(() => _answers[qIndex] = option);
    Future.delayed(const Duration(milliseconds: 220), () {
      if (!mounted) return;
      if (qIndex < surveyQuestions.length - 1) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                SurveyMbtiScreen(answers: _answers.cast<SurveyOption>()),
          ),
        );
      }
    });
  }

  void _back() {
    if (_current > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    } else {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_current + 1) / surveyQuestions.length;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(CupertinoIcons.chevron_back),
          onPressed: _back,
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 진행바
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: context.cs.surfaceContainerHighest,
                  valueColor:
                  AlwaysStoppedAnimation(context.cs.primary),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(), // 선택으로만 진행
                onPageChanged: (i) => setState(() => _current = i),
                itemCount: surveyQuestions.length,
                itemBuilder: (context, qi) {
                  final q = surveyQuestions[qi];
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(28, 12, 28, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Q${qi + 1}.',
                                style: AppTextStyles.headline2
                                    .copyWith(color: context.cs.primary)),
                            Text('${qi + 1} / ${surveyQuestions.length}',
                                style: AppTextStyles.caption),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(q.question, style: AppTextStyles.headline2),
                        const SizedBox(height: 28),
                        ...List.generate(q.options.length, (oi) {
                          final opt = q.options[oi];
                          final selected = _answers[qi] == opt;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _optionCard(
                              context,
                              labelChar: String.fromCharCode(65 + oi), // A,B,C,D
                              option: opt,
                              selected: selected,
                              onTap: () => _select(qi, opt),
                            ),
                          );
                        }),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _optionCard(BuildContext context,
      {required String labelChar,
        required SurveyOption option,
        required bool selected,
        required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? context.cs.primary.withOpacity(0.08)
              : context.cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? context.cs.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            if (option.emoji.isNotEmpty) ...[
              Text(option.emoji, style: const TextStyle(fontSize: 26)),
              const SizedBox(width: 14),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(labelChar,
                      style: AppTextStyles.caption.copyWith(
                        color: selected
                            ? context.cs.primary
                            : context.cs.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      )),
                  const SizedBox(height: 2),
                  Text(option.label,
                      style: AppTextStyles.body
                          .copyWith(fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}