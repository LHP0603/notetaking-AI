import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/system_config.dart';
import '../repositories/system_config_repository.dart';

class GetConfig {
  final SystemConfigRepository repository;

  GetConfig(this.repository);

  Future<Either<Failure, SystemConfig>> call(String configKey) async {
    return await repository.getConfig(configKey);
  }
}

