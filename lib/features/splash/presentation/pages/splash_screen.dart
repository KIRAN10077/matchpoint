import 'dart:async';
import 'package:matchpoint/core/services/storage/user_session_service.dart';
import 'package:matchpoint/features/dashboard/presentation/pages/home_screen.dart';
import 'package:matchpoint/features/onboarding/presentation/pages/onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();

    // Animation for logo
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();

    // Decide navigation after splash
    _decideNavigation();
  }

  Future<void> _decideNavigation() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    // Check SharedPreferences for login state
    final userSession = ref.read(userSessionServiceProvider);
    final isLoggedIn = userSession.isLoggedIn();

    if (isLoggedIn) {
      // If logged in, go directly to HomeScreen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      // If not logged in, go to Onboarding / Login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    final gradientTop = isDarkTheme
        ? const Color.fromARGB(255, 32, 39, 46)
        : const Color.fromARGB(255, 145, 240, 211);
    final gradientBottom = isDarkTheme
        ? const Color.fromARGB(255, 18, 23, 30)
        : const Color.fromARGB(255, 108, 238, 158);

    return Scaffold(
      backgroundColor: isDarkTheme
          ? const Color.fromARGB(255, 16, 22, 28)
          : const Color.fromARGB(137, 255, 255, 255),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              gradientTop,
              gradientBottom,
            ],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeIn,
            child: Column(
              children: [
                const SizedBox(height: 250),
                Image.asset(
                  'assets/images/matchpoint_logo_final.png',
                  height: 300,
                ),
                Text(
                  "MatchPoint",
                  style: GoogleFonts.audiowide(
                    fontSize: 35,
                    color: isDarkTheme ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
