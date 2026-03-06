import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiEndpoints {
  ApiEndpoints._();

  // Configuration
  // Default Android target is a physical device on the same LAN.
  // Set `USE_ANDROID_EMULATOR_HOST=true` for Android emulator.
  static const bool useAndroidEmulatorHost = bool.fromEnvironment(
    'USE_ANDROID_EMULATOR_HOST',
    defaultValue: false,
  );
  static const String _ipAddress = '172.26.0.111';
  static const int _port = 5000;
  static const String _apiHostOverride = String.fromEnvironment('API_HOST', defaultValue: '');

  // Base URLs
  static String get _host {
    // Allows host override without changing source code:
    // flutter run --dart-define API_HOST=192.168.1.78
    if (_apiHostOverride.trim().isNotEmpty) return _apiHostOverride.trim();
    if (kIsWeb || Platform.isIOS) return 'localhost';
    if (Platform.isAndroid) {
      return useAndroidEmulatorHost ? '10.0.2.2' : _ipAddress;
    }
    return 'localhost';
  }

  static String get serverUrl => 'http://$_host:$_port';
  static String get baseUrl => '$serverUrl/api/auth';
  static String get mediaServerUrl => serverUrl;

  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  static const String authLogin = '/login';
  static const String authRegister = '/register';
  static const String authProfile = '/profile';
  static const String authForgotPassword = '/forgot-password';
  static const String authResetPassword = '/reset-password';

  static String authProfileById(String id) => '$baseUrl/profile/$id';
}
