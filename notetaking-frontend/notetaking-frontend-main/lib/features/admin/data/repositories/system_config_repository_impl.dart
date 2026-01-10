import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/system_config.dart';
import '../../domain/repositories/system_config_repository.dart';
import '../datasources/system_config_remote_data_source.dart';
import '../datasources/system_config_local_data_source.dart';
import '../models/system_config_model.dart';

class SystemConfigRepositoryImpl implements SystemConfigRepository {
  final SystemConfigRemoteDataSource remoteDataSource;
  final SystemConfigLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  SystemConfigRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, SystemConfig>> getConfig(String configKey) async {
    if (await networkInfo.isConnected) {
      try {
        final configModel = await remoteDataSource.getConfig(configKey);
        await localDataSource.cacheConfig(configModel);
        return Right(configModel);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('Failed to get config: $e'));
      }
    } else {
      // Try to get cached config when offline
      final cachedConfig = await localDataSource.getCachedConfig(configKey);
      if (cachedConfig != null) {
        return Right(cachedConfig);
      }
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, List<SystemConfig>>> getAllConfigs() async {
    if (await networkInfo.isConnected) {
      try {
        final configModels = await remoteDataSource.getAllConfigs();
        // Cache all configs
        for (final config in configModels) {
          await localDataSource.cacheConfig(config);
        }
        return Right(configModels);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('Failed to get all configs: $e'));
      }
    } else {
      // Try to get cached configs when offline
      final cachedConfigs = await localDataSource.getCachedConfigs();
      return Right(cachedConfigs);
    }
  }

  @override
  Future<Either<Failure, SystemConfig>> updateConfig(SystemConfig config) async {
    if (await networkInfo.isConnected) {
      try {
        final configModel = SystemConfigModel.fromEntity(config);
        final updatedConfig = await remoteDataSource.updateConfig(configModel);
        await localDataSource.cacheConfig(updatedConfig);
        return Right(updatedConfig);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('Failed to update config: $e'));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }
}

