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

  test('Signup: rejects empty name after trim', () {
    expect(
      AuthValidators.signup(
        name: '   ',
        email: 'john@gmail.com',
        pass: '1234567',
        confirm: '1234567',
      ),
      'Please fill all fields',
    );
  });

  test('Signup: rejects empty email after trim', () {
    expect(
      AuthValidators.signup(
        name: 'John',
        email: '   ',
        pass: '1234567',
        confirm: '1234567',
      ),
      'Please fill all fields',
    );
  });

  test('Signup: blocks password shorter than 7 chars', () {
    expect(
      AuthValidators.signup(
        name: 'John',
        email: 'john@gmail.com',
        pass: '123456',
        confirm: '123456',
      ),
      'Password must be at least 7 characters',
    );
  });

  test('Signup: accepts uppercase gmail domain', () {
    expect(
      AuthValidators.signup(
        name: 'John',
        email: 'john@GMAIL.COM',
        pass: '1234567',
        confirm: '1234567',
      ),
      isNull,
    );
  });

  test('Signup: returns null for valid values', () {
    expect(
      AuthValidators.signup(
        name: 'John',
        email: 'john@gmail.com',
        pass: '1234567',
        confirm: '1234567',
      ),
      isNull,
    );
  });
}
