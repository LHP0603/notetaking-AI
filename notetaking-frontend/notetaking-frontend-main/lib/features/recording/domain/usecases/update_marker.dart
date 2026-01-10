import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/recording_repository.dart';
import '../entities/marker.dart';

class UpdateMarker {
  final RecordingRepository repository;

  UpdateMarker(this.repository);

  Future<Either<Failure, Marker>> call({
    required int markerId,
    String? label,
    String? type,
    String? description,
  }) async {
    return await repository.updateMarker(
      markerId: markerId,
      label: label,
      type: type,
      description: description,
    );
  }
}

