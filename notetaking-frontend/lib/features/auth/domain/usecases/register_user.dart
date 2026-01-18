import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/usecase.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class RegisterUser implements UseCase<Either<Failure, User>, RegisterParams> {
  final AuthRepository repository;

  RegisterUser(this.repository);

  @override
  Future<Either<Failure, User>> call(RegisterParams params) async {
    return await repository.register(params.email, params.password);
  }
}

class RegisterParams extends Equatable {
  final String email;
  final String password;

  const RegisterParams({
    required this.email,
    required this.password,
  });

  @override
  List<Object> get props => [email, password];
}
