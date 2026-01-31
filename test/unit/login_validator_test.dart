import 'package:flutter_test/flutter_test.dart';
import 'package:matchpoint/features/bottom_screens/presentation/utils/auth_validators.dart';

void main() {
  test('Login: returns error when email or password is empty', () {
    expect(
      AuthValidators.login(email: '', password: '1234567'),
      'Please enter credentials',
    );
    expect(
      AuthValidators.login(email: 'test@gmail.com', password: ''),
      'Please enter credentials',
    );
  });

  test('Login: returns null when email and password are provided', () {
    expect(
      AuthValidators.login(email: 'test@gmail.com', password: '1234567'),
      isNull,
    );
  });
}
