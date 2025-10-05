import 'package:flutter/material.dart';
import 'dashboard_page.dart';
import 'history_page.dart';
import 'settings_page.dart';

// Main navigation widget controlling Dashboard, History, and Settings pages
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0; // Tracks currently selected bottom tab

  // Controller to handle page navigation and preserve scroll/state between tabs
  final PageController _pageController = PageController();

  // Handles tap events on BottomNavigationBar items
  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    _pageController.jumpToPage(index); // Instantly switch to selected page
  }

  @override
  void dispose() {
    // Dispose controller to avoid memory leaks
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // PageView manages swipe navigation between tabs
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          // Update selected index when user swipes between pages
          setState(() {
            _selectedIndex = index;
          });
        },
        // App pages displayed in order
        children: const [
          DashboardPage(),
          HistoryPage(),
          SettingsPage(),
        ],
      ),

      // Bottom navigation bar for quick access to main sections
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex, // Highlights active tab
        onTap: _onItemTapped, // Handles tab selection
        type: BottomNavigationBarType.fixed, // Keeps all icons visible
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart), label: "Dashboard"),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: "History"),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings), label: "Settings"),
        ],
      ),
    );
  }
}
