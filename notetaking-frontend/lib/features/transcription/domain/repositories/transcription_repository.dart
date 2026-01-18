import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../data/models/audio_upload_response.dart';
import '../../data/models/transcription_models.dart';

abstract class TranscriptionRepository {
  Future<Either<Failure, AudioUploadResponse>> uploadAudio(File audioFile);
  Future<Either<Failure, TranscriptionResponse>> transcribeAudio(TranscriptionRequest request);
}