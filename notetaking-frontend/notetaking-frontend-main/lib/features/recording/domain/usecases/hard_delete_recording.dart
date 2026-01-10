import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/recording_repository.dart';

class HardDeleteRecording {
  final RecordingRepository repository;

  HardDeleteRecording(this.repository);

  Future<Either<Failure, void>> call(String recordingId) async {
    return await repository.hardDeleteRecording(recordingId);
  }
}

