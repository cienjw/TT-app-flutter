import 'package:flutter/material.dart';
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: _back,
        ),
        title: Text('${_current + 1} / ${surveyQuestions.length}', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: AppColors.lightGrey,
                  valueColor: const AlwaysStoppedAnimation(AppColors.primaryPink),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _current = i),
                itemCount: surveyQuestions.length,
                itemBuilder: (context, qi) {
                  final q = surveyQuestions[qi];
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(32, 24, 32, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primaryPink.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Question ${qi + 1}',
                            style: const TextStyle(
                              color: AppColors.primaryPink,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(q.question, style: AppTextStyles.headline2.copyWith(height: 1.4)),
                        const SizedBox(height: 40),
                        ...List.generate(q.options.length, (oi) {
                          final opt = q.options[oi];
                          final selected = _answers[qi] == opt;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _optionCard(
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

  Widget _optionCard({
    required SurveyOption option,
    required bool selected,
    required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryBlue.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primaryBlue : AppColors.lightGrey,
            width: 2,
          ),
          boxShadow: selected ? [
            BoxShadow(
              color: AppColors.primaryBlue.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ] : [],
        ),
        child: Row(
          children: [
            if (option.emoji.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: selected ? Colors.white : AppColors.lightGrey,
                  shape: BoxShape.circle,
                ),
                child: Text(option.emoji, style: const TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 16),
            ],
            Expanded(
              child: Text(
                option.label,
                style: AppTextStyles.body.copyWith(
                  fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                  color: selected ? AppColors.primaryBlue : AppColors.textPrimary,
                ),
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle_rounded, color: AppColors.primaryBlue),
          ],
        ),
      ),
    );
  }
}
