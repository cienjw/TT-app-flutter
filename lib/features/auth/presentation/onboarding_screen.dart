import 'package:flutter/material.dart';
import '../../../core/theme/app_text_styles.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('관심사 선택')),
      body: Center(
        child: Text('관심사 입력 화면 (추후 구현)', style: AppTextStyles.body),
      ),
    );
  }
}