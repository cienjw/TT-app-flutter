import 'package:flutter/material.dart';

class ChatDetailScreen extends StatelessWidget {
  final String title;
  const ChatDetailScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(icon: const Icon(Icons.settings), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildMessage('오늘 저녁 뭐 먹을까요?', isMe: false),
                _buildMessage('내 생각엔 마라탕 어때요? 너무 좋음!', isMe: true),
                _buildMessage('오케이! 그럼 마라탕 먹으러 가요!', isMe: false),
                _buildMessage('좋아요!', isMe: true),
              ],
            ),
          ),
          _buildAIAdviceSection(context),
          _buildInputSection(),
        ],
      ),
    );
  }

  Widget _buildMessage(String text, {required bool isMe}) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isMe ? Colors.deepPurple : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          text,
          style: TextStyle(color: isMe ? Colors.white : Colors.black),
        ),
      ),
    );
  }

  Widget _buildAIAdviceSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.purple[50],
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: Colors.deepPurple),
          const SizedBox(width: 10),
          const Expanded(
            child: Text('AI 조언: 서로의 이색 취미 나누기, 좋아하는 음식 이야기하기'),
          ),
          TextButton(
            onPressed: () => _showAIAdviceDialog(context),
            child: const Text('자세히'),
          ),
        ],
      ),
    );
  }

  void _showAIAdviceDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('AI 조언', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            const Text('대화 주제를 추천해드려요!'),
            const SizedBox(height: 10),
            const Text('• 서로의 이색 취미 나누기'),
            const Text('• 좋아하는 음식 이야기하기'),
            const Text('• 주말 계획 공유하기'),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
                child: const Text('적용하기'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputSection() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey[300]!))),
      child: Row(
        children: [
          IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: () {}),
          const Expanded(
            child: TextField(
              decoration: InputDecoration(hintText: '메시지 입력하기...', border: InputBorder.none),
            ),
          ),
          IconButton(icon: const Icon(Icons.send, color: Colors.deepPurple), onPressed: () {}),
        ],
      ),
    );
  }
}
