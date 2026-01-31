import 'package:matchpoint/core/error/failures.dart';
import 'package:matchpoint/core/usecases/app_usecase.dart';
import 'package:matchpoint/features/auth/data/repositories/auth_repository.dart';
import 'package:matchpoint/features/auth/domain/entities/auth_entity.dart';
import 'package:matchpoint/features/auth/domain/repositories/auth_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RegisterUsecaseParams extends Equatable {
  final String email;
  final String? password;
  final String username;

  const RegisterUsecaseParams({
    required this.email,
    required this.password,
    required this.username,
  });

  @override
  List<Object?> get props => [email, password, username];
  
}

final registerUsecaseProvider = Provider<RegisterUsecase>((ref){
  final iauthRepository = ref.read(authRepositoryProvider);
  return RegisterUsecase(iauthRepository: iauthRepository);
});

class RegisterUsecase 
    implements UsecaseWithParams<bool, RegisterUsecaseParams>{

        final IAuthRepository _iauthRepository;

        RegisterUsecase({required IAuthRepository iauthRepository})
        : _iauthRepository = iauthRepository;

      @override
      Future<Either<Failure, bool>> call(RegisterUsecaseParams params) {
        final entity = AuthEntity(
          email: params.email,
          password: params.password,
          username: params.username,
          fullName: params.username,
        );
        return _iauthRepository.register(entity);
      }
        
    }
