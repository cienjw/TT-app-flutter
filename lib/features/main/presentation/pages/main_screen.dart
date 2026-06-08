import 'package:flutter/material.dart';
import 'footprint_tab.dart';
import 'matching_tab.dart';
import 'chat_list_tab.dart';
import 'bluetooth_tab.dart';
import 'profile_tab.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

    final List<Widget> _pages = [
    const FootprintTab(),
    const MatchingTab(),
    const ChatListTab(),
    const BluetoothTab(),
    const ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.location_on), label: '발자취'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: '매칭'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble), label: '채팅방'),
          BottomNavigationBarItem(icon: Icon(Icons.bluetooth), label: '블루투스'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: '프로필'),
        ],
      ),
    );
  }
}
