import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/recording.dart';
import '../repositories/recording_repository.dart';

class GetRecordings {
  final RecordingRepository repository;

  GetRecordings(this.repository);

  Future<Either<Failure, List<Recording>>> call({
    String? folderId,
    bool? isTrashed,
    String? search,
    String? tag,
    int? page,
    int? pageSize,
  }) async {
    return await repository.getRecordings(
      folderId: folderId,
      isTrashed: isTrashed,
      search: search,
      tag: tag,
      page: page,
      pageSize: pageSize,
    );
  }
}

