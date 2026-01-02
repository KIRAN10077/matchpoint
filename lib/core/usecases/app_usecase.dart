import 'package:dartz/dartz.dart';
import 'package:matchpoint/core/error/failures.dart';
import 'package:matchpoint/features/auth/domain/usecases/register_usecase.dart';

abstract interface class UsecaseWithParams<SuccessType, Params> {
  Future<Either<Failure, SuccessType>> call(Params params);
}


