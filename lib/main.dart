import 'package:matchpoint/app/app.dart';
import 'package:matchpoint/core/services/hive/hive_service.dart';
import 'package:matchpoint/core/services/storage/user_session_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (WebViewPlatform.instance == null) {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        WebViewPlatform.instance = AndroidWebViewPlatform();
        break;
      case TargetPlatform.iOS:
        WebViewPlatform.instance = WebKitWebViewPlatform();
        break;
      default:
        break;
    }
  }

  try {
    final hiveService = HiveService();
    await hiveService.init();
    await hiveService.openBoxes();

    final sharedPreferences = await SharedPreferences.getInstance();

    runApp(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        ],
        child: const App(),
      ),
    );
  } catch (e) {
    debugPrint('Error initializing app: $e');

    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Error initializing app: $e'),
          ),
        ),
      ),
    );
  }
}
