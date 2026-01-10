import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/recording_repository.dart';

class RemoveTag {
  final RecordingRepository repository;

  RemoveTag(this.repository);

  Future<Either<Failure, void>> call({
    required String recordingId,
    required String tag,
  }) async {
    return await repository.removeTag(recordingId: recordingId, tag: tag);
  }
}

