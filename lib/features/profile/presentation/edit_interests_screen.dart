import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/profile_repository.dart';
import '../domain/profile_provider.dart';

class EditInterestsScreen extends ConsumerStatefulWidget {
  const EditInterestsScreen({super.key});
  @override
  ConsumerState<EditInterestsScreen> createState() => _EditInterestsScreenState();
}

class _EditInterestsScreenState extends ConsumerState<EditInterestsScreen> {
  List<InterestItem> _all = [];
  final Set<int> _selected = {};
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final all = await ProfileRepository().getAllInterests();
      final me = await ProfileRepository().getMe();
      _all = all;
      _selected.addAll(me.interestIds);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (_selected.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('관심사를 3개 이상 선택해주세요.')));
      return;
    }
    setState(() => _saving = true);
    try {
      await ProfileRepository().updateInterests(_selected.toList());
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('관심사 재설정',
            style: AppTextStyles.title.copyWith(color: context.cs.onSurface)),
        actions: [
          TextButton(onPressed: _saving ? null : _save, child: const Text('저장')),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('${_selected.length}개 선택됨 (최소 3개)',
                  style: AppTextStyles.caption),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _all.map((it) {
                  final sel = _selected.contains(it.id);
                  return ChoiceChip(
                    label: Text(it.name),
                    selected: sel,
                    onSelected: (_) => setState(() {
                      if (sel) {
                        _selected.remove(it.id);
                      } else {
                        _selected.add(it.id);
                      }
                    }),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}