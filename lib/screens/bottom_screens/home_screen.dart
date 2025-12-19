import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Widget _sportCard({
  required String title,
  required IconData icon,
}) {
  return Container(
    width: 120, // 👈 bigger card
    margin: const EdgeInsets.only(right: 14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16), // smoother corners
      border: Border.all(color: Colors.black12),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 38, // 👈 bigger icon
          color: Colors.black87,
        ),
        const SizedBox(height: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14, // 👈 bigger text
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}



  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children:[
              SizedBox(height: 12),
              Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    // Left side: logo
    Image.asset(
      'assets/images/matchpoint_logo_final.png',
      height: 45,
    ),

    // Right side: welcome text + avatar
    Row(
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'WELCOME BACK',
              style: TextStyle(
                fontSize: 10,
                color: Colors.black54,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'User',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(width: 10),
        const CircleAvatar(
          radius: 18,
          backgroundColor: Colors.black12,
          child: Icon(Icons.person, color: Colors.black54),
        ),
      ],
    ),
  ],
),

SizedBox(height: 24),
Container(
  height: 45,
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(25),
    border: Border.all(color: Colors.black12),
  ),
  child: Row(
  children: [
    const SizedBox(width: 16),
    Expanded(
      child: TextField(
        decoration: const InputDecoration(
          hintText: 'Search',
          hintStyle: TextStyle(color: Colors.black45),
          border: InputBorder.none,
          isDense: true,
        ),
      ),
    ),
    const Icon(Icons.search, color: Colors.black54),
    const SizedBox(width: 16),
  ],
),

),

SizedBox(height: 16),

const Text(
  'Sports',
  style: TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
  ),
),
const SizedBox(height: 10),

LayoutBuilder(
  builder: (context, constraints) {
    final isTablet = constraints.maxWidth >= 600;

    return SizedBox(
      height: 130,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? (constraints.maxWidth - 90 * 4) / 2 : 0,
        ),
        children: [
          _sportCard(title: 'Football', icon: Icons.sports_soccer),
          _sportCard(title: 'Cricket', icon: Icons.sports_cricket),
          _sportCard(title: 'Basketball', icon: Icons.sports_basketball),
          _sportCard(title: 'Swimming', icon: Icons.pool),
          _sportCard(title: 'Badminton', icon: Icons.sports_tennis),
          _sportCard(title: 'Tennis', icon: Icons.sports_tennis),
          _sportCard(title: 'Volleyball', icon: Icons.sports_volleyball),
        ],
      ),
    );
  },
),

const SizedBox(height: 20),


      ],
    ),
  ),
),
);
}
}