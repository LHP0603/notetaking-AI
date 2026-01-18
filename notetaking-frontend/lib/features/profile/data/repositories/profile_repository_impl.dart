import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../auth/data/datasources/auth_local_data_source.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_local_data_source.dart';
import '../datasources/profile_remote_data_source.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource remoteDataSource;
  final ProfileLocalDataSource localDataSource;
  final AuthLocalDataSource authLocalDataSource;
  final NetworkInfo networkInfo;

  ProfileRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.authLocalDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, UserProfile>> getProfile() async {
    if (await networkInfo.isConnected) {
      try {
        final accessToken = await authLocalDataSource.getAccessToken();
        if (accessToken == null) {
          return const Left(AuthFailure('Not authenticated'));
        }

        final profile = await remoteDataSource.getProfile(accessToken);
        await localDataSource.cacheProfile(profile);
        return Right(profile);
      } on UnauthorizedException {
        return const Left(AuthFailure('Session expired'));
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('Failed to get profile: $e'));
      }
    } else {
      // Try to get cached profile when offline
      final cachedProfile = await localDataSource.getCachedProfile();
      if (cachedProfile != null) {
        return Right(cachedProfile);
      }
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, UserProfile>> updateProfile({
    String? name,
    String? email,
    String? avatarUrl,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }

    try {
      final accessToken = await authLocalDataSource.getAccessToken();
      if (accessToken == null) {
        return const Left(AuthFailure('Not authenticated'));
      }

      final profile = await remoteDataSource.updateProfile(
        accessToken: accessToken,
        name: name,
        email: email,
        avatarUrl: avatarUrl,
      );
      await localDataSource.cacheProfile(profile);
      return Right(profile);
    } on UnauthorizedException {
      return const Left(AuthFailure('Session expired'));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to update profile: $e'));
    }
  }

  @override
  Future<Either<Failure, String>> updateAvatar(String imagePath) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }

    try {
      final accessToken = await authLocalDataSource.getAccessToken();
      if (accessToken == null) {
        return const Left(AuthFailure('Not authenticated'));
      }

      final avatarUrl = await remoteDataSource.updateAvatar(
        accessToken: accessToken,
        imagePath: imagePath,
      );
      return Right(avatarUrl);
    } on UnauthorizedException {
      return const Left(AuthFailure('Session expired'));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to update avatar: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await localDataSource.clearAllData();
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Failed to logout: $e'));
    }
  }
}

