import 'package:flutter/material.dart';
import '../../../core/theme/app_text_styles.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('환영 화면 (추후 구현)', style: AppTextStyles.body)),
    );
  }
}