import 'package:matchpoint/core/services/storage/user_session_service.dart';

class FakeUserSessionService implements UserSessionService {
  bool cleared = false;

  String? _userId = 'u1';
  String? _email = 'test@gmail.com';
  String? _fullName = 'Test User';
  String? _token = 'token';

  @override
  String? getCurrentUserFullName() => _fullName;

  @override
  String? getCurrentUserEmail() => _email;

  @override
  String? getCurrentUserId() => _userId;

  @override
  bool isLoggedIn() => _token != null;

  @override
  Future<String?> getToken() async => _token;

  @override
  Future<void> saveToken(String token) async {
    _token = token;
  }

  @override
  Future<void> saveUserSession({
    required String userId,
    required String email,
    required String fullName,
    String? phoneNumber,
  }) async {
    _userId = userId;
    _email = email;
    _fullName = fullName;
    // phoneNumber not used in ProfileScreen, ignore safely
  }

  @override
  Future<void> clearSession() async {
    cleared = true;
    _userId = null;
    _email = null;
    _fullName = null;
    _token = null;
  }
}
