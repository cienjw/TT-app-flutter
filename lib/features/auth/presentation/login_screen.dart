import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_button.dart';
import '../domain/auth_provider.dart';
import '../../main/presentation/main_screen.dart';
import 'terms_screen.dart';
import '../../chat/domain/chat_provider.dart';
import '../../profile/domain/profile_provider.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(authProvider).isLoading;

    Future<void> handleLogin(Future<bool> Function() loginFn) async {
      try {
        final isNewUser = await loginFn();
        if (!context.mounted) return;

        // 이전 계정의 캐시 무효화 (새 토큰 저장 후이므로 안전)
        ref.invalidate(myProfileProvider);
        ref.invalidate(myGroupsProvider);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
            isNewUser ? const TermsScreen() : MainScreen(),
          ),
        );
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('로그인 실패: $e'),
              backgroundColor: AppColors.error),
        );
      }
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(flex: 2),

              // 앱 아이콘
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.people_alt_rounded,
                    color: Colors.white, size: 30),
              ),
              const SizedBox(height: 28),

              Text('새로운 만남,\n부담 없이', style: AppTextStyles.headline1),
              const SizedBox(height: 14),
              Text(
                'AI가 나와 잘 맞는 소규모 그룹을\n자동으로 연결해드려요.',
                style: AppTextStyles.body.copyWith(
                    color: AppColors.textSecondary, height: 1.6),
              ),

              const Spacer(flex: 2),

              AppButton(
                label: '카카오로 시작하기',
                variant: AppButtonVariant.kakao,
                isLoading: isLoading,
                onPressed: () => handleLogin(
                    ref.read(authProvider.notifier).loginWithKakao),
              ),
              const SizedBox(height: 12),
              AppButton(
                label: 'Google로 시작하기',
                variant: AppButtonVariant.google,
                isLoading: isLoading,
                onPressed: () => handleLogin(
                    ref.read(authProvider.notifier).loginWithGoogle),
              ),

              const SizedBox(height: 32),
              Center(
                child: Text(
                  '로그인 시 서비스 이용약관 및\n개인정보처리방침에 동의하는 것으로 간주됩니다.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}