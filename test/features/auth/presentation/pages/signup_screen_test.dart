
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:matchpoint/core/services/storage/user_session_service.dart';
import 'package:matchpoint/features/auth/presentation/pages/signup_screen.dart';
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

  testWidgets('Signup: shows snackbar when fields are empty', (tester) async {
    await tester.pumpWidget(wrapWithApp(const SignupScreen()));

    await tester.tap(find.text('CREATE ACCOUNT'));
    await tester.pump();

    expect(find.text('Please fill all fields'), findsOneWidget);
  });

  testWidgets('Signup: non-gmail email shows snackbar', (tester) async {
    await tester.pumpWidget(wrapWithApp(const SignupScreen()));

    // Fill fields
    await tester.enterText(find.byType(TextField).at(0), 'John Doe');
    await tester.enterText(find.byType(TextField).at(1), 'john@yahoo.com');
    await tester.enterText(find.byType(TextField).at(2), '1234567');
    await tester.enterText(find.byType(TextField).at(3), '1234567');

    await tester.tap(find.text('CREATE ACCOUNT'));
    await tester.pump();

    expect(find.text('Only Gmail addresses are allowed'), findsOneWidget);
  });

  testWidgets('Signup: renders expected core widgets', (tester) async {
    await tester.pumpWidget(wrapWithApp(const SignupScreen()));

    expect(find.text('MatchPoint'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(4));
    expect(find.text('CREATE ACCOUNT'), findsOneWidget);
  });

  testWidgets('Signup: short password shows snackbar', (tester) async {
    await tester.pumpWidget(wrapWithApp(const SignupScreen()));

    await tester.enterText(find.byType(TextField).at(0), 'John Doe');
    await tester.enterText(find.byType(TextField).at(1), 'john@gmail.com');
    await tester.enterText(find.byType(TextField).at(2), '123456');
    await tester.enterText(find.byType(TextField).at(3), '123456');

    await tester.tap(find.text('CREATE ACCOUNT'));
    await tester.pump();

    expect(find.text('Password must be at least 7 characters'), findsOneWidget);
  });

  testWidgets('Signup: password mismatch shows snackbar', (tester) async {
    await tester.pumpWidget(wrapWithApp(const SignupScreen()));

    await tester.enterText(find.byType(TextField).at(0), 'John Doe');
    await tester.enterText(find.byType(TextField).at(1), 'john@gmail.com');
    await tester.enterText(find.byType(TextField).at(2), '1234567');
    await tester.enterText(find.byType(TextField).at(3), '7654321');

    await tester.tap(find.text('CREATE ACCOUNT'));
    await tester.pump();

    expect(find.text('Passwords do not match'), findsOneWidget);
  });

  testWidgets('Signup: valid input does not show validation snackbar', (tester) async {
    await tester.pumpWidget(wrapWithApp(const SignupScreen()));

    await tester.enterText(find.byType(TextField).at(0), 'John Doe');
    await tester.enterText(find.byType(TextField).at(1), 'john@gmail.com');
    await tester.enterText(find.byType(TextField).at(2), '1234567');
    await tester.enterText(find.byType(TextField).at(3), '1234567');

    await tester.tap(find.text('CREATE ACCOUNT'));
    await tester.pump();

    expect(find.text('Please fill all fields'), findsNothing);
    expect(find.text('Only Gmail addresses are allowed'), findsNothing);
    expect(find.text('Password must be at least 7 characters'), findsNothing);
    expect(find.text('Passwords do not match'), findsNothing);
  });

  testWidgets('Signup: shows login footer text', (tester) async {
    await tester.pumpWidget(wrapWithApp(const SignupScreen()));

    final footerText = find.byWidgetPredicate(
      (widget) =>
          widget is RichText &&
          widget.text.toPlainText().contains('Already have an account? Log In'),
    );

    expect(footerText, findsOneWidget);
  });
}
