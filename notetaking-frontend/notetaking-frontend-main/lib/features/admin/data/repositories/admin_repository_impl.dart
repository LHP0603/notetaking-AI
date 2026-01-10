import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../auth/domain/entities/user.dart';
import '../datasources/admin_remote_data_source.dart';
import '../../domain/repositories/admin_repository.dart';

class AdminRepositoryImpl implements AdminRepository {
  final AdminRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  AdminRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<User>>> getUsers({
    String? email,
    int? tierId,
    bool? isActive,
    int? page,
    int? pageSize,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final users = await remoteDataSource.getUsers(
          email: email,
          tierId: tierId,
          isActive: isActive,
          page: page,
          pageSize: pageSize,
        );
        return Right(users);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('Failed to get users: $e'));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, User>> updateUser(
    String userId, {
    int? tierId,
    String? role,
    bool? isActive,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final user = await remoteDataSource.updateUser(
          userId,
          tierId: tierId,
          role: role,
          isActive: isActive,
        );
        return Right(user);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('Failed to update user: $e'));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, List<Tier>>> getTiers() async {
    if (await networkInfo.isConnected) {
      try {
        final tiers = await remoteDataSource.getTiers();
        return Right(tiers);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('Failed to get tiers: $e'));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, Tier>> createTier({
    required String name,
    required double monthlyPrice,
    required int maxStorageMb,
    required int maxAiMinutesMonthly,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final tier = await remoteDataSource.createTier(
          name: name,
          monthlyPrice: monthlyPrice,
          maxStorageMb: maxStorageMb,
          maxAiMinutesMonthly: maxAiMinutesMonthly,
        );
        return Right(tier);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('Failed to create tier: $e'));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, Tier>> updateTier(
    int tierId, {
    String? name,
    double? monthlyPrice,
    int? maxStorageMb,
    int? maxAiMinutesMonthly,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final tier = await remoteDataSource.updateTier(
          tierId,
          name: name,
          monthlyPrice: monthlyPrice,
          maxStorageMb: maxStorageMb,
          maxAiMinutesMonthly: maxAiMinutesMonthly,
        );
        return Right(tier);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('Failed to update tier: $e'));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteTier(int tierId) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.deleteTier(tierId);
        return const Right(null);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('Failed to delete tier: $e'));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, List<AuditLog>>> getAuditLogs({
    String? userId,
    String? action,
    DateTime? startDate,
    DateTime? endDate,
    int? page,
    int? pageSize,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final logs = await remoteDataSource.getAuditLogs(
          userId: userId,
          action: action,
          startDate: startDate,
          endDate: endDate,
          page: page,
          pageSize: pageSize,
        );
        return Right(logs);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('Failed to get audit logs: $e'));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }
}
