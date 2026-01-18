import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/summary.dart';
import '../repositories/summary_repository.dart';

class GetSummary {
  final SummaryRepository repository;

  GetSummary(this.repository);

  Future<Either<Failure, Summary>> call(String transcriptionId) async {
    return await repository.getSummary(transcriptionId);
  }
}

