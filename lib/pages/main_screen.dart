import 'package:flutter/material.dart';
import 'package:health_app_3/pages/home_page.dart';
import 'package:health_app_3/pages/profile_page.dart'; // Replace with your actual profile page
import 'package:health_app_3/pages/bottom_navbar.dart';
import 'package:health_app_3/pages/scanmeal_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const HomePage(),
    const ScanMealPage(),    // Replace with your actual scan page widget
    const ProfilePage(), // Replace with your actual profile page widget
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _selectedIndex,
        onItemSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}