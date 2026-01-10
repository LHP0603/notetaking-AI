import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/audit_log.dart';
import '../repositories/audit_log_repository.dart';

class CreateAuditLog {
  final AuditLogRepository repository;

  CreateAuditLog(this.repository);

  Future<Either<Failure, AuditLog>> call(AuditLog auditLog) async {
    return await repository.createAuditLog(auditLog);
  }
}

