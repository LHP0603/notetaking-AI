import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/system_config.dart';
import '../repositories/system_config_repository.dart';

class GetAllConfigs {
  final SystemConfigRepository repository;

  GetAllConfigs(this.repository);

  Future<Either<Failure, List<SystemConfig>>> call() async {
    return await repository.getAllConfigs();
  }
}

