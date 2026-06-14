import 'package:flutter/material.dart';
import '../../matching/presentation/home_screen.dart';
import '../../chat/presentation/chatrooms_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../../core/theme/app_colors.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0; // 기본 탭: 홈

  final _screens = const [
    HomeScreen(),
    ChatroomsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: NavigationBar(
          backgroundColor: Colors.white,
          elevation: 0,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          selectedIndex: _currentIndex,
          indicatorColor: AppColors.primaryPink.withOpacity(0.1),
          onDestinationSelected: (i) => setState(() => _currentIndex = i),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined, color: AppColors.textSecondary),
              selectedIcon: Icon(Icons.home_rounded, color: AppColors.primaryPink),
              label: '홈',
            ),
            NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline_rounded, color: AppColors.textSecondary),
              selectedIcon: Icon(Icons.chat_bubble_rounded, color: AppColors.primaryPink),
              label: '채팅',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded, color: AppColors.textSecondary),
              selectedIcon: Icon(Icons.person_rounded, color: AppColors.primaryPink),
              label: '프로필',
            ),
          ],
        ),
      ),
    );
  }
}
