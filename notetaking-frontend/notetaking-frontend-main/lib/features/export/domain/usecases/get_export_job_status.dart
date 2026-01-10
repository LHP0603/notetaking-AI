import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/export_repository.dart';
import '../entities/export_job.dart';

class GetExportJobStatus {
  final ExportRepository repository;

  GetExportJobStatus(this.repository);

  Future<Either<Failure, ExportJob>> call(int jobId) async {
    return await repository.getExportJobStatus(jobId);
  }
}

