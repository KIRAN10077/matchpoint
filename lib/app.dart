import 'package:flutter/material.dart';
import 'package:matchpoint/screens/splash_screen.dart';
import 'package:matchpoint/theme/theme_data.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: getApplicationTheme(),
      home: SplashScreen(),
    );
  }
}