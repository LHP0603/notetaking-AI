import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/user.dart';

abstract class AuthRepository {
  Future<Either<Failure, Map<String, String>>> login(
    String email,
    String password,
  );
  Future<Either<Failure, Map<String, String>>> signup(
    String name,
    String email,
    String password,
  );
  Future<Either<Failure, void>> logout();
  Future<Either<Failure, User?>> getCurrentUser();
  Future<Either<Failure, Map<String, String>>> refresh(String refreshToken);
  Future<Either<Failure, Map<String, dynamic>>> fetchCurrentUser(
    String accessToken,
  );
}
