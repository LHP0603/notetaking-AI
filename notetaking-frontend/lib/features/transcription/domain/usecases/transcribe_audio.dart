import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/transcription_repository.dart';
import '../../data/models/transcription_models.dart';

class TranscribeAudio {
  final TranscriptionRepository repository;

  TranscribeAudio(this.repository);

  Future<Either<Failure, TranscriptionResponse>> call(TranscriptionRequest request) async {
    return await repository.transcribeAudio(request);
  }
}