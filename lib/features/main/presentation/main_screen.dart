import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../footprints/presentation/footprints_screen.dart';
import '../../chat/presentation/chatrooms_screen.dart';
import '../../profile/presentation/profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 1; // 기본 탭: 채팅방

  final _screens = const [
    FootprintsScreen(),
    ChatroomsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(CupertinoIcons.map),
            selectedIcon: Icon(CupertinoIcons.map_fill),
            label: '발자취',
          ),
          NavigationDestination(
            icon: Icon(CupertinoIcons.chat_bubble),
            selectedIcon: Icon(CupertinoIcons.chat_bubble_fill),
            label: '채팅방',
          ),
          NavigationDestination(
            icon: Icon(CupertinoIcons.person),
            selectedIcon: Icon(CupertinoIcons.person_fill),
            label: '프로필',
          ),
        ],
      ),
    );
  }
}