import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/transcription_repository.dart';
import '../entities/transcription_response.dart';

class TranscribeRecording {
  final TranscriptionRepository repository;

  TranscribeRecording(this.repository);

  /// Transcribe a recording - POST /recordings/:id/transcribe
  Future<Either<Failure, TranscriptionResponse>> call(String recordingId) async {
    return await repository.transcribeRecording(recordingId);
  }
}

