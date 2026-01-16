import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:matchpoint/core/services/storage/user_session_service.dart';
import 'package:matchpoint/features/auth/domain/usecases/login_usecase.dart';
import 'package:matchpoint/features/auth/domain/usecases/register_usecase.dart';
import 'package:matchpoint/features/auth/domain/entities/auth_entity.dart' as domain_auth;
import 'package:matchpoint/features/auth/presentation/state/auth_state.dart';

class AuthViewModel extends StateNotifier<AuthState> {
  final RegisterUsecase _registerUsecase;
  final LoginUsecase _loginUsecase;
  final UserSessionService _sessionService;

  AuthViewModel({
    required RegisterUsecase registerUsecase,
    required LoginUsecase loginUsecase,
    required UserSessionService sessionService,
  })  : _registerUsecase = registerUsecase,
        _loginUsecase = loginUsecase,
        _sessionService = sessionService,
        super(const AuthState());

  Future<void> register({
    required String fullName,
    required String username,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.loading);

    final params = RegisterUsecaseParams(
      fullName: fullName,
      username: username,
      email: email,
      password: password,
    );

    final result = await _registerUsecase(params);

    result.fold(
      (failure) {
        state = state.copyWith(
          status: AuthStatus.error,
          errorMessage: failure.message,
        );
      },
      (_) {
        state = state.copyWith(
          status: AuthStatus.registered,
        );
      },
    );
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.loading);

    final params = LoginUsecaseParams(
      email: email,
      password: password,
    );

    final result = await _loginUsecase(params);

    result.fold(
      (failure) {
        state = state.copyWith(
          status: AuthStatus.error,
          errorMessage: failure.message,
        );
      },
      (authEntity) {
        // Save session data after successful login
        _sessionService.saveUserSession(
          userId: authEntity.authId ?? '',
          email: authEntity.email,
          fullName: authEntity.fullName,
        );
        debugPrint('💾 Session saved for: ${authEntity.email}');
        
        // Convert domain AuthEntity to state AuthEntity
        final stateAuthEntity = AuthEntity(
          authId: authEntity.authId ?? '',
          email: authEntity.email,
          fullName: authEntity.fullName,
        );
        
        state = state.copyWith(
          status: AuthStatus.authenticated,
          authEntity: stateAuthEntity,
        );
      },
    );
  }

  // Check if user has an existing session
  Future<void> checkExistingSession() async {
    final isLoggedIn = _sessionService.isLoggedIn();
    debugPrint('🔍 Checking session... isLoggedIn: $isLoggedIn');

    if (isLoggedIn) {
      final userId = _sessionService.getCurrentUserId();
      final email = _sessionService.getCurrentUserEmail();
      final fullName = _sessionService.getCurrentUserFullName();

      debugPrint('📱 Session data - userId: $userId, email: $email, fullName: $fullName');

      if (userId != null && email != null && fullName != null) {
        debugPrint('✅ Session restored! Authenticated');
        state = state.copyWith(
          status: AuthStatus.authenticated,
          authEntity: AuthEntity(
            authId: userId,
            email: email,
            fullName: fullName,
          ),
        );
      } else {
        debugPrint('❌ Session data incomplete');
        state = state.copyWith(status: AuthStatus.unauthenticated);
      }
    } else {
      debugPrint('❌ No saved session found');
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  // Logout method
  Future<void> logout() async {
    await _sessionService.clearSession();
    state = state.copyWith(
      status: AuthStatus.unauthenticated,
      authEntity: null,
      errorMessage: null,
    );
  }
}

final authViewModelProvider = StateNotifierProvider<AuthViewModel, AuthState>(
  (ref) {
    final registerUsecase = ref.watch(registerUsecaseProvider);
    final loginUsecase = ref.watch(loginUsecaseProvider);
    final sessionService = ref.watch(userSessionServiceProvider);

    return AuthViewModel(
      registerUsecase: registerUsecase,
      loginUsecase: loginUsecase,
      sessionService: sessionService,
    );
  },
);