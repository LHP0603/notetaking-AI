import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/usecase.dart';
import '../entities/audio_file_page.dart';
import '../entities/audio_filter.dart';
import '../repositories/audio_manager_repository.dart';

class GetUploadedAudios
    implements UseCase<Either<Failure, AudioFilePage>, AudioFilter> {
  final AudioManagerRepository repository;

  GetUploadedAudios(this.repository);

  @override
  Future<Either<Failure, AudioFilePage>> call(AudioFilter params) async {
    return await repository.getUploadedAudios(params);
  }
}
