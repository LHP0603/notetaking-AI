import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/supabase/supabase_client.dart';
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
  Future<Either<Failure, Map<String, String>>> login(
    String email,
    String password,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final tokens = await remoteDataSource.login(email, password);
        await localDataSource.cacheTokens(tokens);
        
        // Sync Supabase auth state to enable authenticated storage operations
        try {
          await SupabaseClient.instance.syncAuthState();
        } catch (e) {
          print('Warning: Failed to sync Supabase auth state after login: $e');
        }
        
        return Right(tokens);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } on NetworkException catch (e) {
        return Left(NetworkFailure(e.message));
      } on UnauthorizedException catch (e) {
        return Left(UnauthorizedFailure(e.message));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, Map<String, String>>> signup(
    String name,
    String email,
    String password,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final tokens = await remoteDataSource.signup(name, email, password);
        await localDataSource.cacheTokens(tokens);
        
        try {
          await SupabaseClient.instance.syncAuthState();
        } catch (e) {
          // Log but don't fail signup if Supabase sync fails
          print('Warning: Failed to sync Supabase auth state after signup: $e');
        }
        
        return Right(tokens);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } on NetworkException catch (e) {
        return Left(NetworkFailure(e.message));
      } on ValidationException catch (e) {
        return Left(ValidationFailure(e.message));
      } on EmailConfirmationRequiredException catch (e) {
        return Left(EmailConfirmationRequiredFailure(e.email, e.message));
      } catch (e) {
        // Catch any other exceptions and convert to ServerFailure
        return Left(
          ServerFailure(
            e is Exception && e.toString().contains('Exception')
                ? e
                    .toString()
                    .replaceAll('Exception: ', '')
                    .replaceAll('Exception', '')
                : 'Signup failed: ${e.toString()}',
          ),
        );
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

  @override
  Future<Either<Failure, Map<String, String>>> refresh(
    String refreshToken,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final tokens = await remoteDataSource.refresh(refreshToken);
        await localDataSource.cacheTokens(tokens);
        
        // Sync Supabase auth state after token refresh
        try {
          await SupabaseClient.instance.syncAuthState();
        } catch (e) {
          // Log but don't fail refresh if Supabase sync fails
          print('Warning: Failed to sync Supabase auth state after refresh: $e');
        }
        
        return Right(tokens);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } on NetworkException catch (e) {
        return Left(NetworkFailure(e.message));
      } on ValidationException catch (e) {
        return Left(ValidationFailure(e.message));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> fetchCurrentUser(
    String accessToken,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final userInfo = await remoteDataSource.getCurrentUser(accessToken);
        return Right(userInfo);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } on NetworkException catch (e) {
        return Left(NetworkFailure(e.message));
      } on UnauthorizedException catch (e) {
        return Left(UnauthorizedFailure(e.message));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }
}
