import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/summary_repository.dart';
import '../entities/summary.dart';

class SummarizeRecording {
  final SummaryRepository repository;

  SummarizeRecording(this.repository);

  /// Summarize a recording - POST /recordings/:id/summarize
  Future<Either<Failure, Summary>> call({
    required String recordingId,
    String? summaryStyle,
  }) async {
    return await repository.summarizeRecording(
      recordingId: recordingId,
      summaryStyle: summaryStyle,
    );
  }
}

