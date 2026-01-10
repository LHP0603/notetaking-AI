import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/recording.dart';
import '../repositories/recording_repository.dart';

class RestoreRecording {
  final RecordingRepository repository;

  RestoreRecording(this.repository);

  Future<Either<Failure, Recording>> call(String recordingId) async {
    return await repository.restoreRecording(recordingId);
  }
}

