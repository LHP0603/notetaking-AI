import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/system_config.dart';
import '../repositories/system_config_repository.dart';

class UpdateConfig {
  final SystemConfigRepository repository;

  UpdateConfig(this.repository);

  Future<Either<Failure, SystemConfig>> call(SystemConfig config) async {
    return await repository.updateConfig(config);
  }
}

