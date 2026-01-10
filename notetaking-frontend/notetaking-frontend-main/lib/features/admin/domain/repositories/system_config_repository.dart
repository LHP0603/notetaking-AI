import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/system_config.dart';

abstract class SystemConfigRepository {
  Future<Either<Failure, SystemConfig>> getConfig(String configKey);
  Future<Either<Failure, List<SystemConfig>>> getAllConfigs();
  Future<Either<Failure, SystemConfig>> updateConfig(SystemConfig config);
}

