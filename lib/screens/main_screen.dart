import 'package:flutter/material.dart';

import '../widgets/bottom_navigation.dart';
import 'explore_screen.dart';
import 'favorites_screen.dart';
import 'map_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    MapScreen(),
    ExploreScreen(),
    FavoritesScreen(),
    ProfileScreen(),
  ];

  void _onNavigationItemSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      extendBody: true,
      bottomNavigationBar: MadaGuideBottomNavigation(
        currentIndex: _currentIndex,
        onItemSelected: _onNavigationItemSelected,
      ),
    );
  }
}
