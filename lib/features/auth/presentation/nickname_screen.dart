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
        SnackBar(content: Text('오류: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Text(
                'Meetory에서 사용할\n닉네임을 정해주세요',
                style: AppTextStyles.headline2,
              ),
              const SizedBox(height: 12),
              Text(
                '나를 잘 나타내는 별명을 추천해요.\n안전을 위해 본명은 피해주세요!',
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: 40),
              
              TextField(
                controller: _controller,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  hintText: '닉네임을 입력하세요',
                  counterText: '${_controller.text.length}/20',
                  prefixIcon: const Icon(Icons.alternate_email_rounded, color: AppColors.primaryPink),
                ),
                maxLength: 20,
              ),
              
              const SizedBox(height: 48),
              Text('프로필 캐릭터 선택', style: AppTextStyles.title.copyWith(fontSize: 16)),
              const SizedBox(height: 20),
              
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                ),
                itemCount: ProfileAvatar.presets.length,
                itemBuilder: (context, i) {
                  final selected = _selectedAvatar == i;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedAvatar = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected ? AppColors.primaryPink : Colors.transparent,
                          width: 2.5,
                        ),
                      ),
                      child: ProfileAvatar(
                        imageId: 'avatar_${i + 1}',
                        radius: 30,
                      ),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 48),
              AppButton(
                label: '다음으로',
                isLoading: _isLoading,
                onPressed: _canProceed ? _next : null,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
