import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/usecase.dart';
import '../entities/auth_response.dart';
import '../repositories/auth_repository.dart';

class GetStoredAuth
    implements UseCase<Either<Failure, AuthResponse?>, NoParams> {
  final AuthRepository repository;

  GetStoredAuth(this.repository);

  @override
  Future<Either<Failure, AuthResponse?>> call(NoParams params) async {
    return await repository.getStoredAuth();
  }
}
