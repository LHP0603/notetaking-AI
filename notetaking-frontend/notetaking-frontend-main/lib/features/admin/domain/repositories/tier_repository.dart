import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/tier.dart';

abstract class TierRepository {
  Future<Either<Failure, Tier>> getTier(int tierId);
  Future<Either<Failure, List<Tier>>> getAllTiers();
  Future<Either<Failure, Tier>> createTier(Tier tier);
  Future<Either<Failure, Tier>> updateTier(Tier tier);
  Future<Either<Failure, void>> deleteTier(int tierId);
}

