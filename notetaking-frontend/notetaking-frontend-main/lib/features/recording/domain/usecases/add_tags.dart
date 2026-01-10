import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/recording_repository.dart';
import '../entities/recording_tag.dart';

class AddTags {
  final RecordingRepository repository;

  AddTags(this.repository);

  Future<Either<Failure, List<RecordingTag>>> call({
    required String recordingId,
    required List<String> tags,
  }) async {
    return await repository.addTags(recordingId: recordingId, tags: tags);
  }
}

