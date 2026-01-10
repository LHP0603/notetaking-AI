import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/audit_log.dart';
import '../../domain/repositories/audit_log_repository.dart';
import '../datasources/audit_log_remote_data_source.dart';
import '../models/audit_log_model.dart';

class AuditLogRepositoryImpl implements AuditLogRepository {
  final AuditLogRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  AuditLogRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, AuditLog>> createAuditLog(AuditLog auditLog) async {
    if (await networkInfo.isConnected) {
      try {
        final auditLogModel = AuditLogModel.fromEntity(auditLog);
        final createdLog = await remoteDataSource.createAuditLog(auditLogModel);
        return Right(createdLog);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('Failed to create audit log: $e'));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, List<AuditLog>>> getAuditLogs({
    String? userId,
    String? resourceType,
    String? actionType,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final auditLogModels = await remoteDataSource.getAuditLogs(
          userId: userId,
          resourceType: resourceType,
          actionType: actionType,
          status: status,
          startDate: startDate,
          endDate: endDate,
          limit: limit,
        );
        return Right(auditLogModels);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('Failed to get audit logs: $e'));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, List<AuditLog>>> getUserAuditLogs(String userId) async {
    if (await networkInfo.isConnected) {
      try {
        final auditLogModels = await remoteDataSource.getUserAuditLogs(userId);
        return Right(auditLogModels);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('Failed to get user audit logs: $e'));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }
}

