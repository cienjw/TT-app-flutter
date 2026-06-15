import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class TermsScreen extends StatefulWidget {
  const TermsScreen({Key? key}) : super(key: key);

  @override
  State<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends State<TermsScreen> {
  bool _isServiceAgreed = false;
  bool _isPrivacyAgreed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // 선택 여부에 따른 유연한 연한 컬러 매핑
    final activeBackgroundColor = isDarkMode ? AppColors.termsSelectedDark : AppColors.termsSelectedLight;

    return Scaffold(
      appBar: AppBar(
        title: const Text('약관 동의'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '이용 약관에\n동의가 필요합니다.',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),

              // 1. 서비스 이용약관
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isServiceAgreed = !_isServiceAgreed;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  decoration: BoxDecoration(
                    color: _isServiceAgreed ? activeBackgroundColor : theme.cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isServiceAgreed ? theme.primaryColor.withOpacity(0.3) : Colors.transparent,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isServiceAgreed ? Icons.check_circle : Icons.check_circle_outline,
                        color: _isServiceAgreed ? theme.primaryColor : theme.disabledColor,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '[필수] 서비스 이용약관 동의',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: _isServiceAgreed ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 2. 개인정보 처리방침
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isPrivacyAgreed = !_isPrivacyAgreed;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  decoration: BoxDecoration(
                    color: _isPrivacyAgreed ? activeBackgroundColor : theme.cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isPrivacyAgreed ? theme.primaryColor.withOpacity(0.3) : Colors.transparent,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isPrivacyAgreed ? Icons.check_circle : Icons.check_circle_outline,
                        color: _isPrivacyAgreed ? theme.primaryColor : theme.disabledColor,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '[필수] 개인정보 수집 및 이용 동의',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: _isPrivacyAgreed ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),
              ElevatedButton(
                onPressed: (_isServiceAgreed && _isPrivacyAgreed) ? () {} : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  disabledBackgroundColor: theme.disabledColor.withOpacity(0.12),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('다음', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}