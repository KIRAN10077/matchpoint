import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE1FBFF),
              Color(0xFFCFFFE1),
            ],
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 120),
      Image.asset(
        'assets/images/matchpoint_logo_final.png',
        height: 160,
      ),
      const SizedBox(height: 10),
      Text(
        "MatchPoint",
        style: GoogleFonts.audiowide(
          fontSize: 32,
          color: Colors.black,
        ),
      ),
      const SizedBox(height: 30),
    Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    // Sign Up (tappable, goes to register later)
    Text(
      "Sign Up",
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Colors.black54,
      ),
    ),
    const SizedBox(width: 25),

    // Log In (active)
    Column(
      children: [
        const Text(
          "Log In",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        Container(
          height: 2,
          width: 60,
          margin: const EdgeInsets.only(top: 4),
          color: Colors.blueAccent,
        ),
      ],
    ),
  ],
),
const SizedBox(height: 30),



          ],
        )
      ),
    );
  }
}