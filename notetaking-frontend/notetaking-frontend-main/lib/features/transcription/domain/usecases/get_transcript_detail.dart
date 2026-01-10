import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/transcription_repository.dart';
import '../entities/transcript.dart';
import '../entities/transcript_segment.dart';

class GetTranscriptDetail {
  final TranscriptionRepository repository;

  GetTranscriptDetail(this.repository);

  /// Get transcript detail with segments - GET /transcripts/:id
  Future<Either<Failure, TranscriptDetail>> call(String transcriptId) async {
    return await repository.getTranscriptDetail(transcriptId);
  }
}

/// Response model for transcript detail with segments
class TranscriptDetail {
  final Transcript transcript;
  final List<TranscriptSegment> segments;

  const TranscriptDetail({
    required this.transcript,
    required this.segments,
  });
}

