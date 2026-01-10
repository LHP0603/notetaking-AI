import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/audit_log.dart';
import '../repositories/audit_log_repository.dart';

class GetUserAuditLogs {
  final AuditLogRepository repository;

  GetUserAuditLogs(this.repository);

  Future<Either<Failure, List<AuditLog>>> call(String userId) async {
    return await repository.getUserAuditLogs(userId);
  }
}

