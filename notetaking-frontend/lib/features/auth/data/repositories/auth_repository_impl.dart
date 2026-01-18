import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/utils/auth_error_mapper.dart';
import '../../domain/entities/auth_response.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import '../datasources/auth_local_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, User>> register(String email, String password) async {
    if (await networkInfo.isConnected) {
      try {
        final user = await remoteDataSource.register(email, password);
        await localDataSource.cacheUser(user);
        return Right(user);
      } on ServerException catch (e) {
        return Left(ServerFailure(getErrorMessage(e.message)));
      } on NetworkException catch (e) {
        return Left(NetworkFailure(e.message));
      } on ValidationException catch (e) {
        return Left(ValidationFailure(getErrorMessage(e.message)));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, AuthResponse>> login(
    String email,
    String password,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final authResponse = await remoteDataSource.login(email, password);
        await localDataSource.saveTokens(
          accessToken: authResponse.accessToken,
          refreshToken: authResponse.refreshToken,
        );
        return Right(authResponse);
      } on ServerException catch (e) {
        return Left(ServerFailure(getErrorMessage(e.message)));
      } on NetworkException catch (e) {
        return Left(NetworkFailure(e.message));
      } on UnauthorizedException catch (e) {
        return Left(UnauthorizedFailure(getErrorMessage(e.message)));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, AuthResponse?>> getStoredAuth() async {
    try {
      final accessToken = await localDataSource.getAccessToken();
      final refreshToken = await localDataSource.getRefreshToken();

      if (accessToken != null && refreshToken != null) {
        return Right(
          AuthResponse(
            accessToken: accessToken,
            refreshToken: refreshToken,
            tokenType: 'bearer',
          ),
        );
      }

      if (accessToken == null && refreshToken != null) {
        if (!await networkInfo.isConnected) {
          return const Left(NetworkFailure('No internet connection'));
        }
        try {
          final authResponse = await remoteDataSource.refreshToken(refreshToken);
          await localDataSource.saveTokens(
            accessToken: authResponse.accessToken,
            refreshToken: authResponse.refreshToken,
          );
          return Right(authResponse);
        } on ServerException catch (e) {
          await localDataSource.clearCache();
          return Left(ServerFailure(getErrorMessage(e.message)));
        } on ValidationException catch (e) {
          await localDataSource.clearCache();
          return Left(ValidationFailure(getErrorMessage(e.message)));
        }
      }

      return const Right(null);
    } catch (e) {
      return const Left(CacheFailure('Failed to restore session'));
    }
  }

  @override
  Future<Either<Failure, AuthResponse>> refreshToken(
    String refreshToken,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final authResponse = await remoteDataSource.refreshToken(refreshToken);
        await localDataSource.saveTokens(
          accessToken: authResponse.accessToken,
          refreshToken: authResponse.refreshToken,
        );
        return Right(authResponse);
      } on ServerException catch (e) {
        return Left(ServerFailure(getErrorMessage(e.message)));
      } on NetworkException catch (e) {
        return Left(NetworkFailure(e.message));
      } on ValidationException catch (e) {
        return Left(ValidationFailure(getErrorMessage(e.message)));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await localDataSource.clearCache();
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, User?>> getCurrentUser() async {
    try {
      final user = await localDataSource.getCachedUser();
      return Right(user);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }
}
