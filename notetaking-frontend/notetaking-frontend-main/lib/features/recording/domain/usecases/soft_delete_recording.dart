import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/recording_repository.dart';

class SoftDeleteRecording {
  final RecordingRepository repository;

  SoftDeleteRecording(this.repository);

  Future<Either<Failure, void>> call(String recordingId) async {
    return await repository.softDeleteRecording(recordingId);
  }
}

