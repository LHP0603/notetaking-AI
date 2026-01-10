import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/tier.dart';
import '../repositories/tier_repository.dart';

class GetTier {
  final TierRepository repository;

  GetTier(this.repository);

  Future<Either<Failure, Tier>> call(int tierId) async {
    return await repository.getTier(tierId);
  }
}

