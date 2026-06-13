import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_button.dart';
import '../../main/presentation/main_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Spacer(flex: 2),
              Container(
                width: 96, height: 96,
                decoration: BoxDecoration(
                  color: context.cs.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(CupertinoIcons.checkmark,
                    color: context.cs.onPrimary, size: 56),
              ),
              const SizedBox(height: 36),
              Text('Meetory에\n오신 것을 환영해요!',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.headline1),
              const Spacer(flex: 3),
              AppButton(
                label: '시작하기',
                onPressed: () async {
                  // 온보딩 완료 플래그 저장 → 다음 실행부터 바로 메인탭
                  await SecureStorage.setOnboardingComplete();
                  if (!context.mounted) return;
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const MainScreen()),
                        (route) => false, // 이전 화면 스택 전부 제거
                  );
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}