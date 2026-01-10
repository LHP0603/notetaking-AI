import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/summary_repository.dart';
import '../entities/summary.dart';

class GetLatestSummaryForRecording {
  final SummaryRepository repository;

  GetLatestSummaryForRecording(this.repository);

  /// Get the latest summary for a recording.
  /// Returns null if no summary exists after generation attempt.
  Future<Either<Failure, Summary?>> call(String recordingId) async {
    return await repository.getLatestSummaryForRecording(recordingId);
  }
}

