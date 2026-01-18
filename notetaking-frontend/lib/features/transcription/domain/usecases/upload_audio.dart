import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/transcription_repository.dart';
import '../../data/models/audio_upload_response.dart';

class UploadAudio {
  final TranscriptionRepository repository;

  UploadAudio(this.repository);

  Future<Either<Failure, AudioUploadResponse>> call(File audioFile) async {
    return await repository.uploadAudio(audioFile);
  }
}