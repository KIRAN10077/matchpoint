
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:matchpoint/core/services/storage/user_session_service.dart';
import 'package:matchpoint/features/auth/presentation/pages/login_screen.dart';
import 'package:matchpoint/features/auth/presentation/view_model/auth_view_model.dart';

import '../../../../helpers/fake_auth_notifier.dart';


void main() {
  late SharedPreferences prefs;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Widget wrapWithApp(Widget child) {
    return ProviderScope(
      overrides: [
        authViewModelProvider.overrideWith(() => FakeAuthViewModel()),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: MaterialApp(home: child),
    );
  }

  testWidgets('Login: shows snackbar when fields are empty', (tester) async {
    await tester.pumpWidget(wrapWithApp(const LoginScreen()));

    await tester.tap(find.text('LOGIN'));
    await tester.pump();

    expect(find.text('Please enter credentials'), findsOneWidget);
  });

  testWidgets('Login: validates and shows error for empty email', (tester) async {
    await tester.pumpWidget(wrapWithApp(const LoginScreen()));

    // Fill only password field
    await tester.enterText(find.byType(TextField).at(1), '1234567');

    await tester.tap(find.text('LOGIN'));
    await tester.pump();

    expect(find.text('Please enter credentials'), findsOneWidget);
  });

  testWidgets('Login: renders expected core widgets', (tester) async {
    await tester.pumpWidget(wrapWithApp(const LoginScreen()));

    expect(find.text('MatchPoint'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.text('LOGIN'), findsOneWidget);
  });

  testWidgets('Login: shows error when password is empty', (tester) async {
    await tester.pumpWidget(wrapWithApp(const LoginScreen()));

    await tester.enterText(find.byType(TextField).at(0), 'test@gmail.com');
    await tester.tap(find.text('LOGIN'));
    await tester.pump();

    expect(find.text('Please enter credentials'), findsOneWidget);
  });

  testWidgets('Login: valid credentials do not show validation snackbar', (tester) async {
    await tester.pumpWidget(wrapWithApp(const LoginScreen()));

    await tester.enterText(find.byType(TextField).at(0), 'test@gmail.com');
    await tester.enterText(find.byType(TextField).at(1), '1234567');
    await tester.tap(find.text('LOGIN'));
    await tester.pump();

    expect(find.text('Please enter credentials'), findsNothing);
  });

  testWidgets('Login: shows email and lock input icons', (tester) async {
    await tester.pumpWidget(wrapWithApp(const LoginScreen()));

    expect(find.byIcon(Icons.email_outlined), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline), findsOneWidget);
  });

  testWidgets('Login: shows create account footer text', (tester) async {
    await tester.pumpWidget(wrapWithApp(const LoginScreen()));

    final footerText = find.byWidgetPredicate(
      (widget) =>
          widget is RichText &&
          widget.text.toPlainText().contains('New here? Create an account'),
    );

    expect(footerText, findsOneWidget);
  });
}
