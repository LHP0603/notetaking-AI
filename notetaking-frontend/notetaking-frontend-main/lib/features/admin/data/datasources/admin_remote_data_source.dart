import 'package:dio/dio.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../auth/data/models/user_model.dart';
import '../models/audit_log_model.dart';
import '../models/tier_model.dart';
import '../../domain/repositories/admin_repository.dart';

abstract class AdminRemoteDataSource {
  Future<List<UserModel>> getUsers({
    String? email,
    int? tierId,
    bool? isActive,
    int? page,
    int? pageSize,
  });

  Future<UserModel> updateUser(
    String userId, {
    int? tierId,
    String? role,
    bool? isActive,
  });

  Future<List<Tier>> getTiers();

  Future<Tier> createTier({
    required String name,
    required double monthlyPrice,
    required int maxStorageMb,
    required int maxAiMinutesMonthly,
  });

  Future<Tier> updateTier(
    int tierId, {
    String? name,
    double? monthlyPrice,
    int? maxStorageMb,
    int? maxAiMinutesMonthly,
  });

  Future<void> deleteTier(int tierId);

  Future<List<AuditLog>> getAuditLogs({
    String? userId,
    String? action,
    DateTime? startDate,
    DateTime? endDate,
    int? page,
    int? pageSize,
  });
}

class AdminRemoteDataSourceImpl implements AdminRemoteDataSource {
  final Dio dio;

  AdminRemoteDataSourceImpl({required this.dio});

  @override
  Future<List<UserModel>> getUsers({
    String? email,
    int? tierId,
    bool? isActive,
    int? page,
    int? pageSize,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (email != null) queryParams['email'] = email;
      if (tierId != null) queryParams['tier_id'] = tierId;
      if (isActive != null) queryParams['is_active'] = isActive;
      if (page != null) queryParams['page'] = page;
      if (pageSize != null) queryParams['page_size'] = pageSize;

      final response = await dio.get(
        '/admin/users',
        queryParameters: queryParams,
      );

      final List<dynamic> jsonList = response.data;
      return jsonList.map((json) => UserModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw ServerException('Failed to load users: ${e.message}');
    }
  }

  @override
  Future<UserModel> updateUser(
    String userId, {
    int? tierId,
    String? role,
    bool? isActive,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (tierId != null) body['tier_id'] = tierId;
      if (role != null) body['role'] = role;
      if (isActive != null) body['is_active'] = isActive;

      final response = await dio.patch('/admin/users/$userId', data: body);

      return UserModel.fromJson(response.data);
    } on DioException catch (e) {
      throw ServerException('Failed to update user: ${e.message}');
    }
  }

  @override
  Future<List<Tier>> getTiers() async {
    try {
      final response = await dio.get('/admin/tiers');

      final List<dynamic> jsonList = response.data;
      return List<Tier>.from(jsonList.map((json) => TierModel.fromJson(json)));
    } on DioException catch (e) {
      throw ServerException('Failed to load tiers: ${e.message}');
    }
  }

  @override
  Future<Tier> createTier({
    required String name,
    required double monthlyPrice,
    required int maxStorageMb,
    required int maxAiMinutesMonthly,
  }) async {
    try {
      final body = {
        'name': name,
        'monthly_price': monthlyPrice,
        'max_storage_mb': maxStorageMb,
        'max_ai_minutes_monthly': maxAiMinutesMonthly,
      };

      final response = await dio.post('/admin/tiers', data: body);

      return TierModel.fromJson(response.data);
    } on DioException catch (e) {
      throw ServerException('Failed to create tier: ${e.message}');
    }
  }

  @override
  Future<Tier> updateTier(
    int tierId, {
    String? name,
    double? monthlyPrice,
    int? maxStorageMb,
    int? maxAiMinutesMonthly,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (monthlyPrice != null) body['monthly_price'] = monthlyPrice;
      if (maxStorageMb != null) body['max_storage_mb'] = maxStorageMb;
      if (maxAiMinutesMonthly != null)
        body['max_ai_minutes_monthly'] = maxAiMinutesMonthly;

      final response = await dio.patch('/admin/tiers/$tierId', data: body);

      return TierModel.fromJson(response.data);
    } on DioException catch (e) {
      throw ServerException('Failed to update tier: ${e.message}');
    }
  }

  @override
  Future<void> deleteTier(int tierId) async {
    try {
      await dio.delete('/admin/tiers/$tierId');
    } on DioException catch (e) {
      throw ServerException('Failed to delete tier: ${e.message}');
    }
  }

  @override
  Future<List<AuditLog>> getAuditLogs({
    String? userId,
    String? action,
    DateTime? startDate,
    DateTime? endDate,
    int? page,
    int? pageSize,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (userId != null) queryParams['user_id'] = userId;
      if (action != null) queryParams['action'] = action;
      if (startDate != null)
        queryParams['start_date'] = startDate.toIso8601String();
      if (endDate != null) queryParams['end_date'] = endDate.toIso8601String();
      if (page != null) queryParams['page'] = page;
      if (pageSize != null) queryParams['page_size'] = pageSize;

      final response = await dio.get(
        '/admin/audit-logs',
        queryParameters: queryParams,
      );

      final List<dynamic> jsonList = response.data;
      return List<AuditLog>.from(
        jsonList.map((json) => AuditLogModel.fromJson(json)),
      );
    } on DioException catch (e) {
      throw ServerException('Failed to load audit logs: ${e.message}');
    }
  }
}
