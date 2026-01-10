import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/recording_repository.dart';
import '../entities/recording_tag.dart';

class GetTags {
  final RecordingRepository repository;

  GetTags(this.repository);

  Future<Either<Failure, List<RecordingTag>>> call(String recordingId) async {
    return await repository.getTags(recordingId);
  }
}

