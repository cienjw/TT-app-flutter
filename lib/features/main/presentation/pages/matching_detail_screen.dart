import 'package:flutter/material.dart';

class MatchingDetailScreen extends StatelessWidget {
  final String rate;
  const MatchingDetailScreen({super.key, required this.rate});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('매칭 상세')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircleAvatar(radius: 60, child: Icon(Icons.person, size: 60)),
              const SizedBox(height: 20),
              Text(rate, style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
              const Text('잘 맞아요!', style: TextStyle(fontSize: 20)),
              const SizedBox(height: 40),
              const Text('공통 관심사', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: ['여행', '카페', '영화', '음악', '사진'].map((e) => Chip(label: Text(e))).toList(),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
                  child: const Text('채팅 요청하기'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
