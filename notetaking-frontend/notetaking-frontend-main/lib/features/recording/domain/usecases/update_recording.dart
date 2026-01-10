import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/recording.dart';
import '../repositories/recording_repository.dart';

class UpdateRecording {
  final RecordingRepository repository;

  UpdateRecording(this.repository);

  Future<Either<Failure, Recording>> call({
    required String recordingId,
    String? title,
    String? folderId,
    bool? isPinned,
    double? lastPlayPosition,
  }) async {
    return await repository.updateRecording(
      recordingId: recordingId,
      title: title,
      folderId: folderId,
      isPinned: isPinned,
      lastPlayPosition: lastPlayPosition,
    );
  }
}

