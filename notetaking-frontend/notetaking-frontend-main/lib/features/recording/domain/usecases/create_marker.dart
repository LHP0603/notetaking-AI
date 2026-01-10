import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/recording_repository.dart';
import '../entities/marker.dart';

class CreateMarker {
  final RecordingRepository repository;

  CreateMarker(this.repository);

  Future<Either<Failure, Marker>> call({
    required String recordingId,
    required double timeSeconds,
    required String label,
    required String type,
    String? description,
  }) async {
    return await repository.createMarker(
      recordingId: recordingId,
      timeSeconds: timeSeconds,
      label: label,
      type: type,
      description: description,
    );
  }
}
