import 'package:flutter_test/flutter_test.dart';
import 'package:matchpoint/features/bottom_screens/presentation/utils/auth_validators.dart';

void main() {
  test('Signup: blocks non-gmail email', () {
    expect(
      AuthValidators.signup(
        name: 'John',
        email: 'john@yahoo.com',
        pass: '1234567',
        confirm: '1234567',
      ),
      'Only Gmail addresses are allowed',
    );
  });

  test('Signup: blocks password mismatch', () {
    expect(
      AuthValidators.signup(
        name: 'John',
        email: 'john@gmail.com',
        pass: '1234567',
        confirm: '7654321',
      ),
      'Passwords do not match',
    );
  });
}
