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
            backgroundColor: context.cs.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = _loading != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // 배경 그라디언트
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                    const Color(0xFF0D0D0D),
                    const Color(0xFF111827),
                    const Color(0xFF0D0D0D),
                  ]
                      : [
                    const Color(0xFFF8F9FF),
                    const Color(0xFFEEF2FF),
                    const Color(0xFFFCF4FF),
                  ],
                ),
              ),
            ),
          ),

          // 상단 장식 원
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.meetorySkyBlue.withOpacity(isDark ? 0.18 : 0.25),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 60,
            left: -80,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.meetoryPink.withOpacity(isDark ? 0.12 : 0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Spacer(flex: 3),

                  // 로고 아이콘
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.meetorySkyBlue,
                          AppColors.meetoryPink,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.meetorySkyBlue
                              .withOpacity(isDark ? 0.4 : 0.3),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: const Icon(CupertinoIcons.person_2_fill,
                        color: Colors.white, size: 40),
                  ),
                  const SizedBox(height: 28),

                  // 앱 이름
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [
                        AppColors.meetoryNavy,
                        AppColors.meetorySkyBlue,
                      ],
                    ).createShader(bounds),
                    child: Text(
                      'Meetory',
                      style: AppTextStyles.headline1.copyWith(
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                        color: Colors.white, // ShaderMask가 덮어씀
                        letterSpacing: -1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  Text(
                    '새로운 만남, 부담 없이',
                    style: AppTextStyles.title.copyWith(
                      color: context.cs.onSurface.withOpacity(0.55),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 설명 칩들
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      _FeatureChip(
                        icon: CupertinoIcons.sparkles,
                        label: 'AI 매칭',
                        isDark: isDark,
                      ),
                      _FeatureChip(
                        icon: CupertinoIcons.person_2,
                        label: '소규모 그룹',
                        isDark: isDark,
                      ),
                      _FeatureChip(
                        icon: CupertinoIcons.shield_fill,
                        label: '안전한 만남',
                        isDark: isDark,
                      ),
                    ],
                  ),

                  const Spacer(flex: 3),

                  // 로그인 버튼들
                  AppButton(
                    label: '카카오로 시작하기',
                    variant: AppButtonVariant.kakao,
                    isLoading: _loading == 'kakao',
                    onPressed: busy
                        ? null
                        : () => _handleLogin('kakao',
                        ref.read(authProvider.notifier).loginWithKakao),
                  ),
                  const SizedBox(height: 12),
                  AppButton(
                    label: 'Google로 시작하기',
                    variant: AppButtonVariant.google,
                    isLoading: _loading == 'google',
                    onPressed: busy
                        ? null
                        : () => _handleLogin('google',
                        ref.read(authProvider.notifier).loginWithGoogle),
                  ),

                  const SizedBox(height: 28),

                  // 하단 안내
                  Text(
                    '로그인 시 서비스 이용약관 및\n개인정보처리방침에 동의하는 것으로 간주됩니다.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.caption.copyWith(
                      color: context.cs.onSurface.withOpacity(0.38),
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;

  const _FeatureChip({
    required this.icon,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1C1C1E)
            : Colors.white.withOpacity(0.75),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.06),
        ),
        boxShadow: isDark
            ? null
            : [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 14,
              color: AppColors.meetorySkyBlue.withOpacity(isDark ? 0.9 : 1.0)),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: context.cs.onSurface.withOpacity(0.7),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}