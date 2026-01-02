import 'package:matchpoint/features/dashboard/presentation/pages/bottom_screens/booking_screen.dart';
import 'package:matchpoint/features/dashboard/presentation/pages/bottom_screens/browse_courts_screen.dart';
import 'package:matchpoint/features/dashboard/presentation/pages/bottom_screens/profile_screen.dart';
import 'package:matchpoint/features/dashboard/presentation/pages/bottom_screens/home_screen.dart';
import 'package:flutter/material.dart';


class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  List<Widget> firstBottomScreen = [
    const HomeScreen(),
    const BrowseCourtsScreen(),
    const BookingScreen(),
    const ProfileScreen() 
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DASHBOARD'),
        backgroundColor: Colors.blue,
        centerTitle: true,
      ),
      body: firstBottomScreen[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
           setState(() {
          _selectedIndex = index;
        });
      },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.sports_basketball),
            label: 'Courts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book_online),
            label: 'Bookings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          )
        ],
      ),
    );
  }
}