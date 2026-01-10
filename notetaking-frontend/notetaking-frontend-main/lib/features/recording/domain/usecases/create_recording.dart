import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/recording.dart';
import '../repositories/recording_repository.dart';

class CreateRecording {
  final RecordingRepository repository;

  CreateRecording(this.repository);

  Future<Either<Failure, Recording>> call({
    required String? folderId,
    required String title,
    required String sourceType, // 'RECORDED' or 'IMPORTED'
  }) async {
    return await repository.createRecording(
      folderId: folderId,
      title: title,
      sourceType: sourceType,
    );
  }
}

