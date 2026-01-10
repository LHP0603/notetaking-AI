import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/transcription_repository.dart';
import '../entities/recording_speaker.dart';

class UpdateSpeaker {
  final TranscriptionRepository repository;

  UpdateSpeaker(this.repository);

  /// Update speaker display name - PATCH /recordings/:id/speakers/:speaker_label
  Future<Either<Failure, RecordingSpeaker>> call({
    required String recordingId,
    required String speakerLabel,
    String? displayName,
    String? color,
  }) async {
    return await repository.updateSpeaker(
      recordingId: recordingId,
      speakerLabel: speakerLabel,
      displayName: displayName,
      color: color,
    );
  }
}

