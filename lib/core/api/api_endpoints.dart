import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiEndpoints {
  ApiEndpoints._();

  // Configuration
  static const bool isPhysicalDevice = false;
  static const String _ipAddress = '192.168.1.78';
  static const int _port = 5000;

  // Base URLs
  static String get _host {
    if (isPhysicalDevice) return _ipAddress;
    if (kIsWeb || Platform.isIOS) return 'localhost';
    if (Platform.isAndroid) return '10.0.2.2';
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
