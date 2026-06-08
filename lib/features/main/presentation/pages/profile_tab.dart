import 'package:flutter/material.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('프로필')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            const CircleAvatar(radius: 50, child: Icon(Icons.person, size: 50)),
            const SizedBox(height: 10),
            const Text('sundayday', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const Text('여성, 영화, 독서, 카페', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 30),
            _buildMenuItem(Icons.edit, '내 정보 수정'),
            _buildMenuItem(Icons.notifications, '알림 설정'),
            _buildMenuItem(Icons.block, '차단한 사용자'),
            _buildMenuItem(Icons.help_outline, '이용 가이드'),
            _buildMenuItem(Icons.logout, '로그아웃', textColor: Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, {Color? textColor}) {
    return ListTile(
      leading: Icon(icon, color: textColor),
      title: Text(title, style: TextStyle(color: textColor)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {},
    );
  }
}
