import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/summary_repository.dart';
import '../entities/summary.dart';

class GetSummaryDetail {
  final SummaryRepository repository;

  GetSummaryDetail(this.repository);

  /// Get summary detail - GET /summaries/:id
  Future<Either<Failure, Summary>> call(String summaryId) async {
    return await repository.getSummaryDetail(summaryId);
  }
}

