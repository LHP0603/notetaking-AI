import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/transcription_repository.dart';
import '../entities/transcript.dart';

class UpdateTranscript {
  final TranscriptionRepository repository;

  UpdateTranscript(this.repository);

  /// Update transcript metadata - PATCH /transcripts/:id
  Future<Either<Failure, Transcript>> call({
    required String transcriptId,
    String? language,
    bool? isActive,
  }) async {
    return await repository.updateTranscript(
      transcriptId: transcriptId,
      language: language,
      isActive: isActive,
    );
  }
}

