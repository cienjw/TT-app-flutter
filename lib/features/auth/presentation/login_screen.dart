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
import '../../../core/network/socket_client.dart';
import '../../footprints/domain/footprint_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  String? _loading; // 'kakao' | 'google' | null

  Future<void> _handleLogin(
      String provider, Future<bool> Function() loginFn) async {
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
          builder: (_) => isNewUser ? const TermsScreen() : MainScreen(),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('로그인 실패: $e'),
            backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = _loading != null;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(flex: 3),
              
              // Meetory Logo Placeholder (or Icon)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.backgroundBlue.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(
                      Icons.auto_stories_rounded,
                      size: 80,
                      color: AppColors.primaryBlue,
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: AppColors.primaryPink,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.chat_bubble_rounded,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              
              const Text(
                'Meetory',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primaryBlue,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 16),
              
              Text(
                '이야기가 만나는 곳,\n우리의 새로운 인연',
                textAlign: TextAlign.center,
                style: AppTextStyles.headline2.copyWith(
                  height: 1.4,
                  color: AppColors.textPrimary.withOpacity(0.8),
                ),
              ),
              
              const Spacer(flex: 2),

              AppButton(
                label: '카카오로 시작하기',
                variant: AppButtonVariant.kakao,
                isLoading: _loading == 'kakao',
                icon: const Icon(Icons.chat_bubble, size: 20, color: Colors.black87),
                onPressed: busy
                    ? null
                    : () => _handleLogin(
                    'kakao', ref.read(authProvider.notifier).loginWithKakao),
              ),
              const SizedBox(height: 16),
              AppButton(
                label: 'Google로 시작하기',
                variant: AppButtonVariant.google,
                isLoading: _loading == 'google',
                icon: Image.network(
                  'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_\"G\"_logo.svg/24px-Google_\"G\"_logo.svg.png',
                  width: 20,
                ),
                onPressed: busy
                    ? null
                    : () => _handleLogin(
                    'google', ref.read(authProvider.notifier).loginWithGoogle),
              ),

              const SizedBox(height: 40),
              Text(
                '로그인 시 서비스 이용약관 및\n개인정보처리방침에 동의하는 것으로 간주됩니다.',
                textAlign: TextAlign.center,
                style: AppTextStyles.caption.copyWith(fontSize: 12),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
