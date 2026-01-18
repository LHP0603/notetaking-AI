import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/recording.dart';
import '../repositories/recording_repository.dart';

class StopRecording {
  final RecordingRepository repository;

  StopRecording(this.repository);

  Future<Either<Failure, Recording>> call() async {
    return await repository.stopRecording();
  }
}





