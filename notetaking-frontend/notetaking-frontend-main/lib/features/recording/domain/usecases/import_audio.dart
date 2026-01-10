import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/recording_repository.dart';

class ImportAudio {
  final RecordingRepository repository;

  ImportAudio(this.repository);

  Future<Either<Failure, File>> call() async {
    return await repository.importAudioFile();
  }
}












