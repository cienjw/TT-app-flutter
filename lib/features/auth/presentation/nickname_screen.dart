import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/profile_avatar.dart';
import 'survey_intro_screen.dart';

class NicknameScreen extends ConsumerStatefulWidget {
  const NicknameScreen({super.key});

  @override
  ConsumerState<NicknameScreen> createState() => _NicknameScreenState();
}

class _NicknameScreenState extends ConsumerState<NicknameScreen> {
  final _controller = TextEditingController();
  int? _selectedAvatar;
  bool _isLoading = false;

  bool get _canProceed =>
      _controller.text.trim().isNotEmpty && _selectedAvatar != null;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (!_canProceed) return;
    setState(() => _isLoading = true);
    try {
      await ApiClient.dio.put('/api/users/me', data: {
        'nickname': _controller.text.trim(),
        'profile_img': 'avatar_${_selectedAvatar! + 1}',
      });
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SurveyIntroScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('오류: $e'), backgroundColor: context.cs.error),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('프로필 설정', style: AppTextStyles.title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.vertical -
                  kToolbarHeight,
            ),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 36),

                  // 헤더
                  Text(
                    '어떻게',
                    style: AppTextStyles.headline1.copyWith(
                      color: context.cs.onSurface,
                    ),
                  ),
                  Text(
                    '불러드릴까요?',
                    style: AppTextStyles.headline1.copyWith(
                      foreground: Paint()
                        ..shader = LinearGradient(
                          colors: [
                            AppColors.meetorySkyBlue,
                            AppColors.meetoryPink,
                          ],
                        ).createShader(
                            const Rect.fromLTWH(0, 0, 240, 40)),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // 닉네임 입력
                  TextField(
                    controller: _controller,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: '예) 심야의_코더',
                      prefixIcon: Icon(
                        Icons.alternate_email,
                        color: context.cs.primary.withOpacity(0.5),
                      ),
                    ),
                    maxLength: 20,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 6, left: 4),
                    child: Text(
                      '나를 잘 표현하는 별명을 추천해요. 안전한 만남을 위해 본명이나 연락처는 피해주세요.',
                      style: AppTextStyles.caption.copyWith(height: 1.5),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // 프로필 사진 섹션 헤더
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 18,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              AppColors.meetorySkyBlue,
                              AppColors.meetoryPink,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '프로필 사진 선택',
                        style: AppTextStyles.title.copyWith(
                          color: context.cs.onSurface,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // 아바타 그리드: 4 × 2 (두 줄)
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 1,
                    ),
                    itemCount: ProfileAvatar.presets.length, // 8개 → 4×2
                    itemBuilder: (context, i) {
                      final selected = _selectedAvatar == i;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedAvatar = i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: selected
                                  ? AppColors.meetorySkyBlue
                                  : Colors.transparent,
                              width: 3,
                            ),
                            boxShadow: selected
                                ? [
                              BoxShadow(
                                color: AppColors.meetorySkyBlue
                                    .withOpacity(isDark ? 0.45 : 0.3),
                                blurRadius: 14,
                                spreadRadius: 2,
                              ),
                            ]
                                : null,
                          ),
                          padding: const EdgeInsets.all(3),
                          child: ProfileAvatar(
                            imageId: 'avatar_${i + 1}',
                            radius: 30,
                          ),
                        ),
                      );
                    },
                  ),

                  const Spacer(),
                  const SizedBox(height: 32),

                  AppButton(
                    label: '시작하기',
                    isLoading: _isLoading,
                    onPressed: _canProceed ? _next : null,
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}