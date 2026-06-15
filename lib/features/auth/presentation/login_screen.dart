import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_button.dart';
import '../domain/auth_provider.dart';
import '../../main/presentation/main_screen.dart';
import 'terms_screen.dart';
import '../../chat/domain/chat_provider.dart';
import '../../profile/domain/profile_provider.dart';
import '../../../core/network/socket_client.dart';
import '../../footprints/domain/footprint_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  String? _loading;

  Future<void> _handleLogin(
      String provider,
      Future<bool> Function() loginFn,
      ) async {
    setState(() => _loading = provider);

    try {
      final isNewUser = await loginFn();

      if (!mounted) return;

      SocketClient.disconnect();

      ref.invalidate(myProfileProvider);
      ref.invalidate(myGroupsProvider);
      ref.invalidate(footprintsProvider);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
          isNewUser ? const TermsScreen() : MainScreen(),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() => _loading = null);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('로그인 실패: $e'),
          backgroundColor: context.cs.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = _loading != null;

    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              /// 로고
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.meetoryPink,
                      AppColors.meetorySkyBlue,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? AppColors.skyBlueLight
                          .withOpacity(0.18)
                          : context.cs.primary
                          .withOpacity(0.28),
                      blurRadius: 28,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: const Icon(
                  CupertinoIcons.person_2_fill,
                  color: Colors.white,
                  size: 42,
                ),
              ),

              const SizedBox(height: 40),

              /// 앱 이름
              Text(
                'Meetory',
                style: AppTextStyles.headline1.copyWith(
                  fontSize: 38,
                  fontWeight: FontWeight.w900,
                  color: isDark
                      ? Colors.white
                      : AppColors.meetoryNavy,
                ),
              ),

              const SizedBox(height: 14),

              /// 서브 타이틀
              Text(
                '새로운 만남, 부담 없이',
                style: AppTextStyles.title.copyWith(
                  color: context.cs.onSurface,
                ),
              ),

              const SizedBox(height: 28),

              /// 설명
              Text(
                'AI가 나와 잘 맞는 소규모 그룹을\n자동으로 연결해드려요.',
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(
                  color: context.cs.onSurfaceVariant,
                  height: 1.7,
                ),
              ),

              const Spacer(flex: 3),

              /// 카카오 로그인
              AppButton(
                label: '카카오로 시작하기',
                variant: AppButtonVariant.kakao,
                isLoading: _loading == 'kakao',
                onPressed: busy
                    ? null
                    : () => _handleLogin(
                  'kakao',
                  ref
                      .read(authProvider.notifier)
                      .loginWithKakao,
                ),
              ),

              const SizedBox(height: 14),

              /// 구글 로그인
              AppButton(
                label: 'Google로 시작하기',
                variant: AppButtonVariant.google,
                isLoading: _loading == 'google',
                onPressed: busy
                    ? null
                    : () => _handleLogin(
                  'google',
                  ref
                      .read(authProvider.notifier)
                      .loginWithGoogle,
                ),
              ),

              const SizedBox(height: 32),

              /// 약관 안내
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurfaceVariant
                      .withOpacity(0.35)
                      : AppColors.lightSurfaceVariant,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  '로그인 시 서비스 이용약관 및\n개인정보처리방침에 동의하는 것으로 간주됩니다.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption.copyWith(
                    color: context.cs.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
              ),

              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }
}