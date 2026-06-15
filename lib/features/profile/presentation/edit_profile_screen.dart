import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/profile_avatar.dart';
import '../data/profile_repository.dart';
import '../domain/profile_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});
  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _nickname = TextEditingController();
  String? _avatar;
  bool _loading = true;
  bool _saving = false;

  static const _avatars = [
    'avatar_1','avatar_2','avatar_3','avatar_4',
    'avatar_5','avatar_6','avatar_7','avatar_8',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final me = await ProfileRepository().getMe();
      _nickname.text = me.nickname;
      _avatar = me.profileImg;
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final name = _nickname.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('닉네임을 입력해주세요.')));
      return;
    }
    setState(() => _saving = true);
    try {
      await ProfileRepository().updateProfile(nickname: name, profileImg: _avatar);
      ref.invalidate(myProfileProvider);
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 실패: $e')));
    }
  }

  @override
  void dispose() {
    _nickname.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('내 정보 수정',
            style: AppTextStyles.title.copyWith(color: context.cs.onSurface)),
        actions: [
          TextButton(onPressed: _saving ? null : _save, child: const Text('저장')),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(child: ProfileAvatar(imageId: _avatar, radius: 44)),
          const SizedBox(height: 24),
          Text('아바타', style: AppTextStyles.caption),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            children: _avatars.map((a) {
              final sel = _avatar == a;
              return GestureDetector(
                onTap: () => setState(() => _avatar = a),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: sel
                        ? Border.all(color: context.cs.primary, width: 3)
                        : null,
                  ),
                  child: ProfileAvatar(imageId: a, radius: 28),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 28),
          Text('닉네임', style: AppTextStyles.caption),
          const SizedBox(height: 8),
          TextField(
            controller: _nickname,
            maxLength: 12,
            decoration: const InputDecoration(hintText: '닉네임'),
          ),
        ],
      ),
    );
  }
}