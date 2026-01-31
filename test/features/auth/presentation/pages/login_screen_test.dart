
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:matchpoint/features/auth/presentation/pages/login_screen.dart';
import 'package:matchpoint/features/auth/presentation/view_model/auth_view_model.dart';

import '../../../../helpers/fake_auth_notifier.dart';


void main() {
  Widget wrapWithApp(Widget child) {
    return ProviderScope(
      overrides: [
        authViewModelProvider.overrideWith(() => FakeAuthViewModel()),
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
}
