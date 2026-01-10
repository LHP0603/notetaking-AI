import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/recording_repository.dart';

class DeleteMarker {
  final RecordingRepository repository;

  DeleteMarker(this.repository);

  Future<Either<Failure, void>> call(int markerId) async {
    return await repository.deleteMarker(markerId);
  }
}

