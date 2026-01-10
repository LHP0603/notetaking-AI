import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/tier_repository.dart';

class DeleteTier {
  final TierRepository repository;

  DeleteTier(this.repository);

  Future<Either<Failure, void>> call(int tierId) async {
    return await repository.deleteTier(tierId);
  }
}

