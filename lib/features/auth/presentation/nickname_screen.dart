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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.vertical,
            ),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 60),
                  Text('닉네임을\n입력해주세요', style: AppTextStyles.headline1),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _controller,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      hintText: '예) 심야의_코더',
                    ),
                    maxLength: 20,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 4),
                    child: Text(
                      '실명보다는 나를 표현하는 별명을 추천해요. 안전한 만남을 위해 본명·연락처는 피해주세요.',
                      style: AppTextStyles.caption,
                    ),
                  ),
                  const SizedBox(height: 36),
                  Text('기본 프로필 사진을 선택해주세요', style: AppTextStyles.title),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    alignment: WrapAlignment.center,
                    children: List.generate(ProfileAvatar.presets.length, (i) {
                      final selected = _selectedAvatar == i;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedAvatar = i),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: selected
                                ? Border.all(color: context.cs.primary, width: 3)
                                : null,
                          ),
                          child: ProfileAvatar(
                            imageId: 'avatar_${i + 1}',
                            radius: 30,
                          ),
                        ),
                      );
                    }),
                  ),
                  const Spacer(),
                  AppButton(
                    label: '다음',
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