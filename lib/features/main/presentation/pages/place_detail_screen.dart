import 'package:flutter/material.dart';

class PlaceDetailScreen extends StatelessWidget {
  final String name;
  const PlaceDetailScreen({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 250, width: double.infinity, color: Colors.grey[300], child: const Icon(Icons.image, size: 100, color: Colors.grey)),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const Text('시흥 정왕동 123-4', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 20),
                  const Text('함께 방문한 사람', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  const Row(
                    children: [
                      CircleAvatar(radius: 20, child: Icon(Icons.person)),
                      SizedBox(width: 8),
                      CircleAvatar(radius: 20, child: Icon(Icons.person)),
                      SizedBox(width: 8),
                      CircleAvatar(radius: 20, child: Icon(Icons.person)),
                    ],
                  ),
                  const SizedBox(height: 30),
                  const Text('장소 정보', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  const Text('감성적인 인테리어가 매력적인 카페입니다. 맛있는 커피와 디저트를 즐겨보세요.'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
