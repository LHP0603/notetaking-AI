import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/upload_job.dart';
import '../repositories/recording_repository.dart';

class UploadRecordingAsync {
  final RecordingRepository repository;

  UploadRecordingAsync(this.repository);

  Future<Either<Failure, UploadJob>> call(File audioFile) async {
    return await repository.uploadRecordingAsync(audioFile);
  }
}
