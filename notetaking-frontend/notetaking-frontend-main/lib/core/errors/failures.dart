import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure(super.message);
}

class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

class EmailConfirmationRequiredFailure extends Failure {
  final String email;
  const EmailConfirmationRequiredFailure(
    this.email, [
    super.message = 'Email confirmation required',
  ]);

  @override
  List<Object> get props => [email, message];
}
