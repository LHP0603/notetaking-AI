import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/transcription_repository.dart';
import '../entities/recording_speaker.dart';

class GetSpeakers {
  final TranscriptionRepository repository;

  GetSpeakers(this.repository);

  /// Get speakers for a recording - GET /recordings/:id/speakers
  Future<Either<Failure, List<RecordingSpeaker>>> call(String recordingId) async {
    return await repository.getSpeakers(recordingId);
  }
}

