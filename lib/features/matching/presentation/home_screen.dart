import 'package:flutter/material.dart';
import '../../../core/theme/app_text_styles.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('TT')),
      body: Center(
        child: Text('홈 화면 (추후 구현)', style: AppTextStyles.body),
      ),
    );
  }
}