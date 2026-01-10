import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/recording.dart';
import '../repositories/recording_repository.dart';

class GetRecordingDetail {
  final RecordingRepository repository;

  GetRecordingDetail(this.repository);

  Future<Either<Failure, Recording>> call(String recordingId) async {
    return await repository.getRecordingDetail(recordingId);
  }
}

