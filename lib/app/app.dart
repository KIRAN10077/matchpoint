import 'dart:async';
import 'dart:math' as math;
import 'package:matchpoint/features/splash/presentation/pages/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:matchpoint/app/theme/theme_data.dart';
import 'package:matchpoint/core/providers/theme_mode_provider.dart';
import 'package:sensors_plus/sensors_plus.dart';


class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  DateTime? _lastShakeAt;
  DateTime? _firstShakeHitAt;
  int _shakeHits = 0;

  static const double _shakeThreshold = 13.0;
  static const Duration _shakeWindow = Duration(milliseconds: 650);
  static const Duration _shakeCooldown = Duration(milliseconds: 900);

  @override
  void initState() {
    super.initState();
    _listenForGlobalThemeShakeToggle();
  }

  @override
  void dispose() {
    _accelerometerSubscription?.cancel();
    super.dispose();
  }

  void _listenForGlobalThemeShakeToggle() {
    _accelerometerSubscription = accelerometerEventStream().listen((event) {
      final now = DateTime.now();
      if (_lastShakeAt != null && now.difference(_lastShakeAt!) < _shakeCooldown) {
        return;
      }

      final gForce = math.sqrt(
        event.x * event.x + event.y * event.y + event.z * event.z,
      );

      if (gForce < _shakeThreshold) return;

      if (_firstShakeHitAt == null || now.difference(_firstShakeHitAt!) > _shakeWindow) {
        _firstShakeHitAt = now;
        _shakeHits = 1;
        return;
      }

      _shakeHits += 1;
      if (_shakeHits < 2) return;

      _lastShakeAt = now;
      _firstShakeHitAt = null;
      _shakeHits = 0;

      ref.read(themeModeProvider.notifier).toggle();
    }, onError: (_) {
      // Ignore sensor stream errors on unsupported platforms.
    });
  }

  @override
  Widget build(BuildContext context) {
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