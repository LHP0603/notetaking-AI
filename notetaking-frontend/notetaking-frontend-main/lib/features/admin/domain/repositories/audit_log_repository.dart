import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/audit_log.dart';

abstract class AuditLogRepository {
  Future<Either<Failure, AuditLog>> createAuditLog(AuditLog auditLog);
  Future<Either<Failure, List<AuditLog>>> getAuditLogs({
    String? userId,
    String? resourceType,
    String? actionType,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  });
  Future<Either<Failure, List<AuditLog>>> getUserAuditLogs(String userId);
}

