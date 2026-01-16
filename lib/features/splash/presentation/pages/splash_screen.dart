import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matchpoint/features/onboarding/presentation/pages/onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Wait 3 seconds for splash to be visible
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    // Always navigate to Onboarding for now
    // The login logic will handle session persistence
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const OnboardingScreen()),
    );
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
                  Color.fromARGB(255, 145, 240, 211),
                   Color.fromARGB(255, 108, 238, 158),
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