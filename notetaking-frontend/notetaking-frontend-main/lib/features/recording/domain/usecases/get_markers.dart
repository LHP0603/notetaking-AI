import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/recording_repository.dart';
import '../entities/marker.dart';

class GetMarkers {
  final RecordingRepository repository;

  GetMarkers(this.repository);

  Future<Either<Failure, List<Marker>>> call(String recordingId) async {
    return await repository.getMarkers(recordingId);
  }
}

