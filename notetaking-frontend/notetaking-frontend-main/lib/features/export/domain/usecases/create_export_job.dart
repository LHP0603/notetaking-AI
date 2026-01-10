import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/export_repository.dart';
import '../entities/export_job.dart';

class CreateExportJob {
  final ExportRepository repository;

  CreateExportJob(this.repository);

  Future<Either<Failure, ExportJob>> call({
    required String recordingId,
    required String exportType,
  }) async {
    return await repository.createExportJob(
      recordingId: recordingId,
      exportType: exportType,
    );
  }
}

