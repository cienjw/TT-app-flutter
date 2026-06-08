import 'package:flutter/material.dart';
import 'package:tt_app/features/onboarding/presentation/pages/onboarding_complete_screen.dart';

class InterestSelectionScreen extends StatefulWidget {
  const InterestSelectionScreen({super.key});

  @override
  State<InterestSelectionScreen> createState() => _InterestSelectionScreenState();
}

class _InterestSelectionScreenState extends State<InterestSelectionScreen> {
  final List<String> _interests = [
    '여행', '영화', '음악', '운동', '독서', '맛집',
    '커피', '드라이브', '사진', '패션', '전시회', '게임',
    'IT', '기타'
  ];
  final Set<String> _selectedInterests = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('관심사 선택')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '관심사를 선택해주세요\n(최대 5개)',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 2.5,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: _interests.length,
                itemBuilder: (context, index) {
                  final interest = _interests[index];
                  final isSelected = _selectedInterests.contains(interest);
                  return FilterChip(
                    label: Text(interest),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          if (_selectedInterests.length < 5) {
                            _selectedInterests.add(interest);
                          }
                        } else {
                          _selectedInterests.remove(interest);
                        }
                      });
                    },
                    selectedColor: Colors.deepPurple[100],
                    checkmarkColor: Colors.deepPurple,
                  );
                },
              ),
            ),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _selectedInterests.isNotEmpty
                    ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const OnboardingCompleteScreen()),
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),
                child: const Text('다음'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
