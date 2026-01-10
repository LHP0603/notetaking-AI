import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/tier.dart';
import '../repositories/tier_repository.dart';

class CreateTier {
  final TierRepository repository;

  CreateTier(this.repository);

  Future<Either<Failure, Tier>> call(Tier tier) async {
    return await repository.createTier(tier);
  }
}

