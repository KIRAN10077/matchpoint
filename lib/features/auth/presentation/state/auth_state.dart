import 'package:equatable/equatable.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error, registered }

class AuthEntity {
  final String authId;
  final String email;
  final String fullName;

  AuthEntity({
    required this.authId,
    required this.email,
    required this.fullName,
  });
}

class AuthState extends Equatable {
  final AuthStatus status;
  final AuthEntity? authEntity;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.authEntity,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    AuthEntity? authEntity,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      authEntity: authEntity ?? this.authEntity,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, authEntity, errorMessage];
}
