import 'package:flutter/material.dart';
import 'matching_detail_screen.dart';

class MatchingTab extends StatelessWidget {
  const MatchingTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('매칭')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('오늘의 성향 매칭', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: 3,
                itemBuilder: (context, index) {
                  final rates = ['87%', '80%', '75%'];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: const CircleAvatar(radius: 30, child: Icon(Icons.person)),
                      title: Text(rates[index], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                      subtitle: const Text('잘 맞아요!'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MatchingDetailScreen(rate: rates[index]),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
            Center(
              child: TextButton(
                onPressed: () {},
                child: const Text('더 많은 사람 보기'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
