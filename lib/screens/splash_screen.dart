import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matchpoint/screens/login_screen.dart';
import 'package:matchpoint/screens/onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // Wait 5 seconds then navigate
    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const OnboardingScreen(),  // change to your target screen
        ),
      );
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(137, 255, 255, 255),
      body: Container(
        decoration: const BoxDecoration(
         gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFE1FBFF), // light aqua
                Color(0xFFCFFFE1), // light green
      ],
    ),
  ),
        child: Center(
          child: Column(
            children: [
              SizedBox(height: 250,),
              Image.asset('assets/images/matchpoint_logo_final.png',height:300,),
              Text("MatchPoint", 
              style: GoogleFonts.audiowide(fontSize: 35, color: Colors.black),
          ),
            ],
          )
        ),
      ),
    );
  }
}