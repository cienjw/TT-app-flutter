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
  bool _terms = false;       // (필수) 이용약관
  bool _privacy = false;     // (필수) 개인정보 처리방침
  bool _marketing = false;   // (선택) 마케팅

  bool get _canProceed => _terms && _privacy;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),
              Text('약관에\n동의해주세요', style: AppTextStyles.headline1),
              const SizedBox(height: 48),

              _TermsItem(
                label: '(필수) 이용약관',
                value: _terms,
                onChanged: (v) => setState(() => _terms = v),
              ),
              const SizedBox(height: 16),
              _TermsItem(
                label: '(필수) 개인정보 처리방침',
                value: _privacy,
                onChanged: (v) => setState(() => _privacy = v),
              ),
              const SizedBox(height: 16),
              _TermsItem(
                label: '(선택) 마케팅 정보 수신 동의',
                value: _marketing,
                onChanged: (v) => setState(() => _marketing = v),
              ),

              const Spacer(),

              AppButton(
                label: '다음',
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
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Checkbox(
              value: value,
              onChanged: (v) => onChanged(v ?? false),
              activeColor: context.cs.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4)),
            ),
            Expanded(
              child: Text(label, style: AppTextStyles.body),
            ),
            Icon(CupertinoIcons.chevron_right,
                color: context.cs.onSurfaceVariant, size: 20),
          ],
        ),
      ),
    );
  }
}