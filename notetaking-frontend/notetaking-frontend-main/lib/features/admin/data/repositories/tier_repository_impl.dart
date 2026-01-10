import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/tier.dart';
import '../../domain/repositories/tier_repository.dart';
import '../datasources/tier_remote_data_source.dart';
import '../models/tier_model.dart';

class TierRepositoryImpl implements TierRepository {
  final TierRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  TierRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, Tier>> getTier(int tierId) async {
    if (await networkInfo.isConnected) {
      try {
        final tierModel = await remoteDataSource.getTier(tierId);
        return Right(tierModel);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('Failed to get tier: $e'));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, List<Tier>>> getAllTiers() async {
    if (await networkInfo.isConnected) {
      try {
        final tierModels = await remoteDataSource.getAllTiers();
        return Right(tierModels);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('Failed to get all tiers: $e'));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, Tier>> createTier(Tier tier) async {
    if (await networkInfo.isConnected) {
      try {
        final tierModel = TierModel.fromEntity(tier);
        final createdTier = await remoteDataSource.createTier(tierModel);
        return Right(createdTier);
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
  Future<Either<Failure, Tier>> updateTier(Tier tier) async {
    if (await networkInfo.isConnected) {
      try {
        final tierModel = TierModel.fromEntity(tier);
        final updatedTier = await remoteDataSource.updateTier(tierModel);
        return Right(updatedTier);
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
}

