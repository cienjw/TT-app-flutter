import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_button.dart';
import 'welcome_screen.dart';

class InterestScreen extends ConsumerStatefulWidget {
  const InterestScreen({super.key});

  @override
  ConsumerState<InterestScreen> createState() => _InterestScreenState();
}

class _InterestScreenState extends ConsumerState<InterestScreen> {
  List<Map<String, dynamic>> _interests = [];
  final Set<int> _selected = {};
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error;

  static const _maxSelection = 5;

  @override
  void initState() {
    super.initState();
    _fetchInterests();
  }

  Future<void> _fetchInterests() async {
    try {
      final res = await ApiClient.dio.get('/api/users/interests');
      setState(() {
        _interests = List<Map<String, dynamic>>.from(res.data);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = '관심사를 불러오지 못했습니다: $e';
        _isLoading = false;
      });
    }
  }

  void _toggle(int id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else if (_selected.length < _maxSelection) {
        _selected.add(id);
      }
    });
  }

  Future<void> _submit() async {
    if (_selected.length < 3) return;
    setState(() => _isSubmitting = true);
    try {
      await ApiClient.dio.put('/api/users/me/interests', data: {
        'interest_ids': _selected.toList(),
      });
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Text('관심사를\n선택해주세요', style: AppTextStyles.headline2),
              const SizedBox(height: 12),
              Text(
                '3개 이상 5개 이하로 골라주세요 (${_selected.length}/5)',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 40),

              Expanded(child: _buildBody()),

              const SizedBox(height: 20),
              AppButton(
                label: _selected.length < 3
                    ? '${3 - _selected.length}개 더 선택해주세요'
                    : '다음으로',
                isLoading: _isSubmitting,
                onPressed: _selected.length >= 3 ? _submit : null,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primaryPink));
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, color: AppColors.error.withOpacity(0.5), size: 48),
            const SizedBox(height: 16),
            Text(_error!, style: AppTextStyles.caption, textAlign: TextAlign.center),
          ],
        ),
      );
    }
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Wrap(
        spacing: 12,
        runSpacing: 14,
        children: _interests.map((interest) {
          final id = interest['id'] as int;
          final name = interest['name'] as String;
          final selected = _selected.contains(id);
          return GestureDetector(
            onTap: () => _toggle(id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: selected ? AppColors.primaryPink : AppColors.lightGrey,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: selected ? AppColors.primaryPink : Colors.transparent,
                  width: 2,
                ),
                boxShadow: selected ? [
                  BoxShadow(
                    color: AppColors.primaryPink.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ] : [],
              ),
              child: Text(
                name,
                style: TextStyle(
                  color: selected ? Colors.white : AppColors.textPrimary,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 15,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
