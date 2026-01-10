import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/recording.dart';
import '../repositories/recording_repository.dart';

class CompleteUpload {
  final RecordingRepository repository;

  CompleteUpload(this.repository);

  Future<Either<Failure, Recording>> call({
    required String recordingId,
    required String filePath,
    required double fileSizeMb,
    required double durationSeconds,
    required String originalFileName,
  }) async {
    return await repository.completeUpload(
      recordingId: recordingId,
      filePath: filePath,
      fileSizeMb: fileSizeMb,
      durationSeconds: durationSeconds,
      originalFileName: originalFileName,
    );
  }
}

