import 'package:matchpoint/features/splash/presentation/pages/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:matchpoint/app/theme/theme_data.dart';
import 'package:matchpoint/core/providers/theme_mode_provider.dart';


class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: getApplicationTheme(),
      darkTheme: getApplicationDarkTheme(),
      themeMode: themeMode,
      home: SplashScreen(),
     );
  }
}