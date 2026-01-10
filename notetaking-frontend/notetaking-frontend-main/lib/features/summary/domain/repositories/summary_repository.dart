import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/summary.dart';

abstract class SummaryRepository {
  // Legacy methods (to be deprecated)
  Future<Either<Failure, Summary>> getSummary(String transcriptionId);
  Future<Either<Failure, Summary>> saveSummary(Summary summary);
  Future<Either<Failure, Summary>> resummarize(String transcriptionId);
  Future<Either<Failure, Summary>> updateActionItem(
    String summaryId,
    String actionItemId,
    bool isCompleted,
  );

  /// Summarize a recording - POST /recordings/:id/summarize
  Future<Either<Failure, Summary>> summarizeRecording({
    required String recordingId,
    String? summaryStyle,
  });

  /// Get summaries for a recording - GET /recordings/:id/summaries
  Future<Either<Failure, List<Summary>>> getSummaries({
    required String recordingId,
    bool? latest,
  });

  /// Get summary detail - GET /summaries/:id
  Future<Either<Failure, Summary>> getSummaryDetail(String summaryId);

  /// Update summary - PATCH /summaries/:id
  Future<Either<Failure, Summary>> updateSummary({
    required String summaryId,
    Map<String, dynamic>? contentStructure,
    String? type,
    bool? isLatest,
  });

  /// Get latest summary for a recording.
  /// Returns null if no summary exists after generation attempt.
  Future<Either<Failure, Summary?>> getLatestSummaryForRecording(
    String recordingId,
  );
}

