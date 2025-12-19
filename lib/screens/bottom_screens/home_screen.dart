import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
      ],
    ),
  ),
),
);
}
}