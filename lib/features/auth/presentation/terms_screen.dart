import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
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
      appBar: AppBar(
        title: Text('약관 동의', style: AppTextStyles.title),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Text('환영합니다!\n서비스 이용을 위해\n약관에 동의해주세요',
                  style: AppTextStyles.headline1.copyWith(
                    color: context.cs.primary,
                    height: 1.3,
                  )
              ),
              const SizedBox(height: 48),

              _TermsItem(
                label: '서비스 이용약관 동의 (필수)',
                value: _terms,
                onChanged: (v) => setState(() => _terms = v),
              ),
              const SizedBox(height: 16),
              _TermsItem(
                label: '개인정보 처리방침 동의 (필수)',
                value: _privacy,
                onChanged: (v) => setState(() => _privacy = v),
              ),
              const SizedBox(height: 16),
              _TermsItem(
                label: '마케팅 정보 수신 동의 (선택)',
                value: _marketing,
                onChanged: (v) => setState(() => _marketing = v),
              ),

              const Spacer(),
              AppButton(
                label: '동의하고 계속하기',
                onPressed: _canProceed
                    ? () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NicknameScreen()),
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
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: value
              ? AppColors.meetoryPink.withOpacity(
            isDark ? 0.10 : 0.08,
          )
              : context.cs.surfaceContainerHighest,

          borderRadius:
          BorderRadius.circular(18),

          border: Border.all(
            color: value
                ? AppColors.meetoryPink
                .withOpacity(
              isDark ? 0.28 : 0.20,
            )
                : Colors.transparent,

            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              value ? CupertinoIcons.check_mark_circled_solid : CupertinoIcons.circle,
              color: value ? context.cs.primary : context.cs.onSurfaceVariant,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.body.copyWith(
                  fontWeight: value ? FontWeight.w600 : FontWeight.normal,
                  color: value ? context.cs.primary : context.cs.onSurface,
                ),
              ),
            ),
            Icon(
              CupertinoIcons.chevron_right,
              size: 16,
              color: context.cs.onSurfaceVariant.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }
}