import 'package:flutter/material.dart';
import 'chat_detail_screen.dart';

class ChatListTab extends StatelessWidget {
  const ChatListTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('채팅방')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: 3,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.group)),
                  title: Text('채팅방 ${index + 1}'),
                  subtitle: const Text('오늘 뭐 하세요?'),
                  trailing: const Text('오후 2:30'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatDetailScreen(title: '채팅방 ${index + 1}'),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add),
                label: const Text('새 채팅방 만들기'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
