import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/export_job.dart';

abstract class ExportRepository {
  /// Create export job - POST /recordings/:id/export
  Future<Either<Failure, ExportJob>> createExportJob({
    required String recordingId,
    required String exportType,
  });

  /// Get export job status - GET /export-jobs/:id
  Future<Either<Failure, ExportJob>> getExportJobStatus(int jobId);
}

