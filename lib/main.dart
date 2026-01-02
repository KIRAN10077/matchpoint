import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:matchpoint/app/app.dart';
import 'package:matchpoint/core/services/hive/hive_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive
  final hiveService = HiveService();
  await hiveService.init();
  await hiveService.openBoxes();
  
  runApp(
    const ProviderScope(
      child: App(),
    ),
  );
}