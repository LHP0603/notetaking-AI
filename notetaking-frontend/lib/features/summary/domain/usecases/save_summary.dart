import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/summary.dart';
import '../repositories/summary_repository.dart';

class SaveSummary {
  final SummaryRepository repository;

  SaveSummary(this.repository);

  Future<Either<Failure, Summary>> call(Summary summary) async {
    return await repository.saveSummary(summary);
  }
}

