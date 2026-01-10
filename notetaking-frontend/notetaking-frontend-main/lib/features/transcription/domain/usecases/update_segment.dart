import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/transcription_repository.dart';
import '../entities/transcript_segment.dart';

class UpdateSegment {
  final TranscriptionRepository repository;

  UpdateSegment(this.repository);

  /// Update transcript segment - PATCH /transcripts/:transcript_id/segments/:segment_id
  Future<Either<Failure, TranscriptSegment>> call({
    required String transcriptId,
    required int segmentId,
    String? content,
    String? speakerLabel,
  }) async {
    return await repository.updateSegment(
      transcriptId: transcriptId,
      segmentId: segmentId,
      content: content,
      speakerLabel: speakerLabel,
    );
  }
}

