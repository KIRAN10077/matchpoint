import 'package:matchpoint/core/error/failures.dart';
import 'package:dartz/dartz.dart';

abstract interface class UsecaseWithParams<SuccessType, Params> {
  Future<Either<Failure, SuccessType>> call(Params params);
}

abstract interface class UsecaseWithout<SuccessType> {
  Future<Either<Failure, SuccessType>> call();
}