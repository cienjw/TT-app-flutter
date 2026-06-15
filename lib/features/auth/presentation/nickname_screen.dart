import 'package:flutter/material.dart';
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
        SnackBar(content: Text('오류: $e'), backgroundColor: context.cs.error),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
          padding: const EdgeInsets.symmetric(horizontal: 28),
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
                  const SizedBox(height: 40),
                  Text('어떻게\n불러드릴까요?', style: AppTextStyles.headline1.copyWith(
                    color: context.cs.primary,
                  )),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _controller,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: '예) 심야의_코더',
                      prefixIcon: Icon(Icons.alternate_email, color: context.cs.primary.withOpacity(0.5)),
                    ),
                    maxLength: 20,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8, left: 4),
                    child: Text(
                      '나를 잘 표현하는 별명을 추천해요. 안전한 만남을 위해 본명이나 연락처는 피해주세요.',
                      style: AppTextStyles.caption.copyWith(
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
                  Text('프로필 사진 선택', style: AppTextStyles.title.copyWith(
                    color: context.cs.secondary,
                  )),
                  const SizedBox(height: 24),
              GridView.count(
                crossAxisCount: 4,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: List.generate(ProfileAvatar.presets.length, (i) {
                        final selected = _selectedAvatar == i;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedAvatar = i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: selected ? context.cs.secondary : Colors.transparent,
                                width: 3,
                              ),
                              boxShadow: selected ? [
                                BoxShadow(
                                  color: context.cs.secondary.withOpacity(0.3),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                )
                              ] : null,
                            ),
                            child: ProfileAvatar(
                              imageId: 'avatar_${i + 1}',
                              radius: 34,
                            ),
                          ),
                        );
                      }),
                    ),
                  const Spacer(),
                  const SizedBox(height: 40),
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