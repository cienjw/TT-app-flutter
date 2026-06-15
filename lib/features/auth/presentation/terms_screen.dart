import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_button.dart';
import 'nickname_screen.dart';

class TermsScreen extends StatefulWidget {
  const TermsScreen({super.key});

  @override
  State<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends State<TermsScreen> {
  bool _terms = false;
  bool _privacy = false;
  bool _marketing = false;

  bool get _canProceed => _terms && _privacy;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppColors.textPrimary),
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
                'Meetory 서비스 이용을 위해\n약관에 동의해주세요',
                style: AppTextStyles.headline2,
              ),
              const SizedBox(height: 12),
              Text(
                '안전하고 즐거운 만남을 위해\n꼭 필요한 절차예요.',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 48),

              _TermsItem(
                label: '(필수) 이용약관 동의',
                value: _terms,
                onChanged: (v) => setState(() => _terms = v),
              ),
              const SizedBox(height: 12),
              _TermsItem(
                label: '(필수) 개인정보 처리방침 동의',
                value: _privacy,
                onChanged: (v) => setState(() => _privacy = v),
              ),
              const SizedBox(height: 12),
              _TermsItem(
                label: '(선택) 마케팅 정보 수신 동의',
                value: _marketing,
                onChanged: (v) => setState(() => _marketing = v),
              ),

              const Spacer(),

              AppButton(
                label: '동의하고 다음으로',
                onPressed: _canProceed
                    ? () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const NicknameScreen()),
                )
                    : null,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _TermsItem extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _TermsItem({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: value ? AppColors.backgroundBlue : AppColors.lightGrey,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: value ? AppColors.primaryBlue.withOpacity(0.5) : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              value ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              color: value ? AppColors.primaryBlue : AppColors.textHint,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.body.copyWith(
                  fontSize: 15,
                  color: value ? AppColors.textPrimary : AppColors.textSecondary,
                  fontWeight: value ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textHint, size: 20),
          ],
        ),
      ),
    );
  }
}
