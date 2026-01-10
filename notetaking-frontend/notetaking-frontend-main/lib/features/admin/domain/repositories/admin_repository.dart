import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../auth/domain/entities/user.dart';
import '../entities/audit_log.dart';
import '../entities/tier.dart';
export '../entities/audit_log.dart';
export '../entities/tier.dart';

abstract class AdminRepository {
  Future<Either<Failure, List<User>>> getUsers({
    String? email,
    int? tierId,
    bool? isActive,
    int? page,
    int? pageSize,
  });

  Future<Either<Failure, User>> updateUser(
    String userId, {
    int? tierId,
    String? role,
    bool? isActive,
  });

  Future<Either<Failure, List<Tier>>> getTiers();

  Future<Either<Failure, Tier>> createTier({
    required String name,
    required double monthlyPrice,
    required int maxStorageMb,
    required int maxAiMinutesMonthly,
  });

  Future<Either<Failure, Tier>> updateTier(
    int tierId, {
    String? name,
    double? monthlyPrice,
    int? maxStorageMb,
    int? maxAiMinutesMonthly,
  });

  Future<Either<Failure, void>> deleteTier(int tierId);

  Future<Either<Failure, List<AuditLog>>> getAuditLogs({
    String? userId,
    String? action,
    DateTime? startDate,
    DateTime? endDate,
    int? page,
    int? pageSize,
  });
}
