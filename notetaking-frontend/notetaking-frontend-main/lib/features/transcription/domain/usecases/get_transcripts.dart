import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/transcription_repository.dart';
import '../entities/transcript.dart';

class GetTranscripts {
  final TranscriptionRepository repository;

  GetTranscripts(this.repository);

  /// Get transcripts for a recording - GET /recordings/:id/transcripts
  Future<Either<Failure, List<Transcript>>> call({
    required String recordingId,
    bool? latest,
  }) async {
    return await repository.getTranscripts(recordingId: recordingId, latest: latest);
  }
}

