import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/usecase.dart';
import '../entities/audio_upload_result.dart';
import '../repositories/audio_manager_repository.dart';

class UploadAudioFile
    implements UseCase<Either<Failure, AudioUploadResult>, File> {
  final AudioManagerRepository repository;

  UploadAudioFile(this.repository);

  @override
  Future<Either<Failure, AudioUploadResult>> call(File params) async {
    return await repository.uploadAudioFile(params);
  }
}
