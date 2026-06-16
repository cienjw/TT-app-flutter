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

  bool get _allChecked => _terms && _privacy && _marketing;

  void _toggleAll() {
    final next = !_allChecked;
    setState(() {
      _terms = next;
      _privacy = next;
      _marketing = next;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('약관 동의', style: AppTextStyles.title),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),

              // 헤더
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          AppColors.meetorySkyBlue,
                          AppColors.meetoryPink,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(CupertinoIcons.doc_text_fill,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '환영합니다!',
                          style: AppTextStyles.headline2.copyWith(
                            color: context.cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '서비스 이용을 위해 약관에 동의해주세요',
                          style: AppTextStyles.caption.copyWith(
                            color: context.cs.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // 전체 동의
              GestureDetector(
                onTap: _toggleAll,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 16),
                  decoration: BoxDecoration(
                    gradient: _allChecked
                        ? LinearGradient(
                      colors: [
                        AppColors.meetorySkyBlue.withOpacity(0.15),
                        AppColors.meetoryPink.withOpacity(0.1),
                      ],
                    )
                        : null,
                    color: _allChecked
                        ? null
                        : (isDark
                        ? const Color(0xFF1C1C1E)
                        : const Color(0xFFF5F5F7)),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _allChecked
                          ? AppColors.meetorySkyBlue.withOpacity(0.5)
                          : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          _allChecked
                              ? CupertinoIcons.checkmark_seal_fill
                              : CupertinoIcons.checkmark_seal,
                          key: ValueKey(_allChecked),
                          color: _allChecked
                              ? AppColors.meetorySkyBlue
                              : context.cs.onSurface.withOpacity(0.3),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '전체 동의하기',
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w700,
                          color: _allChecked
                              ? context.cs.onSurface
                              : context.cs.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // 구분선
              Row(
                children: [
                  Expanded(
                      child: Divider(
                          color: context.cs.onSurface.withOpacity(0.08))),
                ],
              ),

              const SizedBox(height: 12),

              // 개별 항목
              _TermsItem(
                label: '서비스 이용약관',
                badge: '필수',
                badgeColor: context.cs.primary,
                value: _terms,
                isDark: isDark,
                onChanged: (v) => setState(() => _terms = v),
              ),
              const SizedBox(height: 10),
              _TermsItem(
                label: '개인정보 처리방침',
                badge: '필수',
                badgeColor: context.cs.primary,
                value: _privacy,
                isDark: isDark,
                onChanged: (v) => setState(() => _privacy = v),
              ),
              const SizedBox(height: 10),
              _TermsItem(
                label: '마케팅 정보 수신',
                badge: '선택',
                badgeColor: context.cs.onSurface.withOpacity(0.35),
                value: _marketing,
                isDark: isDark,
                onChanged: (v) => setState(() => _marketing = v),
              ),

              const Spacer(),

              AppButton(
                label: '동의하고 계속하기',
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
  final String badge;
  final Color badgeColor;
  final bool value;
  final bool isDark;
  final ValueChanged<bool> onChanged;

  const _TermsItem({
    required this.label,
    required this.badge,
    required this.badgeColor,
    required this.value,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: value
              ? (isDark
              ? AppColors.meetorySkyBlue.withOpacity(0.1)
              : AppColors.meetorySkyBlue.withOpacity(0.06))
              : (isDark
              ? const Color(0xFF1C1C1E)
              : const Color(0xFFF5F5F7)),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: value
                ? AppColors.meetorySkyBlue.withOpacity(0.4)
                : Colors.transparent,
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: Icon(
                value
                    ? CupertinoIcons.check_mark_circled_solid
                    : CupertinoIcons.circle,
                key: ValueKey(value),
                color: value
                    ? AppColors.meetorySkyBlue
                    : context.cs.onSurface.withOpacity(0.25),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.body.copyWith(
                  fontWeight:
                  value ? FontWeight.w600 : FontWeight.w400,
                  color: context.cs.onSurface
                      .withOpacity(value ? 1.0 : 0.65),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: badgeColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                badge,
                style: AppTextStyles.caption.copyWith(
                  color: badgeColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              CupertinoIcons.chevron_right,
              size: 14,
              color: context.cs.onSurface.withOpacity(0.25),
            ),
          ],
        ),
      ),
    );
  }
}