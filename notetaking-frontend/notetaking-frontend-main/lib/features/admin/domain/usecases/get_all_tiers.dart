import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/tier.dart';
import '../repositories/tier_repository.dart';

class GetAllTiers {
  final TierRepository repository;

  GetAllTiers(this.repository);

  Future<Either<Failure, List<Tier>>> call() async {
    return await repository.getAllTiers();
  }
}

