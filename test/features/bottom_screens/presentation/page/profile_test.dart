
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:matchpoint/core/providers/profile_provider.dart';
import 'package:matchpoint/core/services/storage/user_session_service.dart';
import 'package:matchpoint/features/auth/presentation/pages/signup_screen.dart';
import 'package:matchpoint/features/bottom_screens/presentation/page/profile.dart';

import '../../../../helpers/fake_user_session_service.dart';
import '../../../../helpers/mock_dio.dart';

void main() {
  Widget wrapWithApp({
    required FakeUserSessionService fakeSession,
  }) {
    final mockDio = MockDio();

    // ✅ FIX: ProfileController needs (Dio, UserSessionService)
    final controller = ProfileController(mockDio, fakeSession);

    return ProviderScope(
      overrides: [
        // session provider override
        userSessionServiceProvider.overrideWithValue(fakeSession),

        // ✅ override profileProvider with controller
        profileProvider.overrideWith((ref) => controller),
      ],
      child: const MaterialApp(home: ProfileScreen()),
    );
  }

  testWidgets('Profile: tapping camera opens bottom sheet', (tester) async {
    final fakeSession = FakeUserSessionService();

    await tester.pumpWidget(wrapWithApp(fakeSession: fakeSession));
    await tester.pump(); // initState microtask

    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Test User'), findsOneWidget);
    expect(find.text('test@gmail.com'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.camera_alt));
    await tester.pumpAndSettle();

    expect(find.text('Take photo'), findsOneWidget);
    expect(find.text('Choose from gallery'), findsOneWidget);
  });

  testWidgets('Profile: logout navigates to SignupScreen', (tester) async {
    final fakeSession = FakeUserSessionService();

    await tester.pumpWidget(wrapWithApp(fakeSession: fakeSession));
    await tester.pump();

    await tester.tap(find.text('Logout'));
    await tester.pumpAndSettle();

    expect(find.byType(SignupScreen), findsOneWidget);
    expect(fakeSession.cleared, isTrue);
  });
}
