import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_button.dart';
import 'interest_screen.dart';

class NicknameScreen extends ConsumerStatefulWidget {
  const NicknameScreen({super.key});

  @override
  ConsumerState<NicknameScreen> createState() => _NicknameScreenState();
}

class _NicknameScreenState extends ConsumerState<NicknameScreen> {
  final _controller = TextEditingController();
  int? _selectedAvatar; // 0, 1, 2
  bool _isLoading = false;

  // 프리셋 아바타 3종 (색상 + 아이콘)
  static const _avatars = [
    (color: Color(0xFFB39DDB), icon: CupertinoIcons.smiley),
    (color: Color(0xFF80CBC4), icon: CupertinoIcons.smiley_fill),
    (color: Color(0xFFFFCC80), icon: CupertinoIcons.star_fill),
  ];

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
        MaterialPageRoute(builder: (_) => const InterestScreen()),
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
                      hintText: '예) pododang_dodang',
                    ),
                    maxLength: 20,
                  ),
                  const SizedBox(height: 40),

                  Text('기본 프로필 사진을 선택해주세요', style: AppTextStyles.title),
                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (i) {
                      final avatar = _avatars[i];
                      final selected = _selectedAvatar == i;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedAvatar = i),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: selected
                                ? Border.all(color: context.cs.primary, width: 3)
                                : null,
                          ),
                          child: CircleAvatar(
                            radius: 36,
                            backgroundColor: avatar.color,
                            child: Icon(avatar.icon,
                                color: Colors.white, size: 32),
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