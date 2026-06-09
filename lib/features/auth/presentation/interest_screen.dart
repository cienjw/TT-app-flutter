import 'package:flutter/material.dart';
import '../../../core/theme/app_text_styles.dart';

class InterestScreen extends StatelessWidget {
  const InterestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('관심사 선택 (추후 구현)', style: AppTextStyles.body)),
    );
  }
}