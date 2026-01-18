import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/recording_repository.dart';

class StartRecording {
  final RecordingRepository repository;

  StartRecording(this.repository);

  Future<Either<Failure, void>> call() async {
    return await repository.startRecording();
  }
}





