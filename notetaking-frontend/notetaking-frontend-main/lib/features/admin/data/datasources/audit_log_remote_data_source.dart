import 'package:dio/dio.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/audit_log_model.dart';

abstract class AuditLogRemoteDataSource {
  Future<AuditLogModel> createAuditLog(AuditLogModel auditLog);
  Future<List<AuditLogModel>> getAuditLogs({
    String? userId,
    String? resourceType,
    String? actionType,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  });
  Future<List<AuditLogModel>> getUserAuditLogs(String userId);
}

class AuditLogRemoteDataSourceImpl implements AuditLogRemoteDataSource {
  final Dio dio;

  AuditLogRemoteDataSourceImpl({required this.dio});

  @override
  Future<AuditLogModel> createAuditLog(AuditLogModel auditLog) async {
    try {
      final response = await dio.post(
        AppConstants.adminAuditLogsEndpoint,
        data: auditLog.toJson(),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return AuditLogModel.fromJson(response.data);
      } else {
        throw Exception('Failed to create audit log');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }

  @override
  Future<List<AuditLogModel>> getAuditLogs({
    String? userId,
    String? resourceType,
    String? actionType,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (userId != null) queryParams['user_id'] = userId;
      if (resourceType != null) queryParams['resource_type'] = resourceType;
      if (actionType != null) queryParams['action_type'] = actionType;
      if (status != null) queryParams['status'] = status;
      if (startDate != null) queryParams['start_date'] = startDate.toIso8601String();
      if (endDate != null) queryParams['end_date'] = endDate.toIso8601String();
      if (limit != null) queryParams['limit'] = limit;

      final response = await dio.get(
        AppConstants.adminAuditLogsEndpoint,
        queryParameters: queryParams,
      );
      if (response.statusCode == 200) {
        return (response.data as List)
            .map((json) => AuditLogModel.fromJson(json))
            .toList();
      } else {
        throw Exception('Failed to get audit logs');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }

  @override
  Future<List<AuditLogModel>> getUserAuditLogs(String userId) async {
    try {
      final response = await dio.get('/admin/audit-logs/user/$userId');
      if (response.statusCode == 200) {
        return (response.data as List)
            .map((json) => AuditLogModel.fromJson(json))
            .toList();
      } else {
        throw Exception('Failed to get user audit logs');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }
}

