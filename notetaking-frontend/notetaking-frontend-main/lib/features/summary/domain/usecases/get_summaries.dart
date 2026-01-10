import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/summary_repository.dart';
import '../entities/summary.dart';

class GetSummaries {
  final SummaryRepository repository;

  GetSummaries(this.repository);

  /// Get summaries for a recording - GET /recordings/:id/summaries
  Future<Either<Failure, List<Summary>>> call({
    required String recordingId,
    bool? latest,
  }) async {
    return await repository.getSummaries(recordingId: recordingId, latest: latest);
  }
}

