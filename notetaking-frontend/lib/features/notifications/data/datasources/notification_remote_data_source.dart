import 'package:dio/dio.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/notification_list_response.dart';
import '../models/notification_model.dart';

abstract class NotificationRemoteDataSource {
  Future<NotificationListResponse> getNotifications({
    bool? isRead,
    String? notificationType,
    int skip = 0,
    int limit = 20,
  });

  Future<int> getUnreadCount();

  Future<NotificationModel> getNotificationById(int id);

  Future<int> markAsRead(List<int> notificationIds);

  Future<int> markAllAsRead();
}

class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  final Dio dio;

  NotificationRemoteDataSourceImpl({required this.dio});

  @override
  Future<NotificationListResponse> getNotifications({
    bool? isRead,
    String? notificationType,
    int skip = 0,
    int limit = 20,
  }) async {
    try {
      int _intFrom(dynamic value, {int fallback = 0}) {
        if (value is int) {
          return value;
        }
        if (value is num) {
          return value.toInt();
        }
        if (value is String) {
          return int.tryParse(value) ?? fallback;
        }
        return fallback;
      }

      final queryParams = <String, dynamic>{
        'skip': skip,
        'limit': limit,
      };

      if (isRead != null) {
        queryParams['is_read'] = isRead;
      }

      if (notificationType != null) {
        queryParams['notification_type'] = notificationType;
      }

      final response = await dio.get(
        AppConstants.notificationsEndpoint,
        queryParameters: queryParams,
      );

      final data = _extractData(
        response,
        fallbackMessage: 'Failed to load notifications',
      );

      final notifications = (data['notifications'] as List)
          .map((item) => NotificationModel.fromJson(item as Map<String, dynamic>))
          .toList();

      return NotificationListResponse(
        notifications: notifications,
        totalCount: _intFrom(data['total_count'], fallback: notifications.length),
        unreadCount: _intFrom(data['unread_count']),
      );
    } on DioException catch (e) {
      throw _handleDioException(
        e,
        fallbackMessage: 'Failed to load notifications',
      );
    }
  }

  @override
  Future<int> getUnreadCount() async {
    try {
      final response = await dio.get(AppConstants.unreadCountEndpoint);

      final data = _extractData(
        response,
        fallbackMessage: 'Failed to get unread count',
      );

      if (data['unread_count'] is int) {
        return data['unread_count'] as int;
      }
      if (data['unread_count'] is num) {
        return (data['unread_count'] as num).toInt();
      }
      return int.tryParse(data['unread_count']?.toString() ?? '') ?? 0;
    } on DioException catch (e) {
      throw _handleDioException(
        e,
        fallbackMessage: 'Failed to get unread count',
      );
    }
  }

  @override
  Future<NotificationModel> getNotificationById(int id) async {
    try {
      final response = await dio.get(AppConstants.notificationById(id));

      final data = _extractData(
        response,
        fallbackMessage: 'Failed to load notification',
      );

      return NotificationModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioException(
        e,
        fallbackMessage: 'Failed to load notification',
      );
    }
  }

  @override
  Future<int> markAsRead(List<int> notificationIds) async {
    try {
      final response = await dio.post(
        AppConstants.markReadEndpoint,
        data: {'notification_ids': notificationIds},
      );

      final data = _extractData(
        response,
        fallbackMessage: 'Failed to mark notifications as read',
      );

      return data['updated_count'] as int? ?? 0;
    } on DioException catch (e) {
      throw _handleDioException(
        e,
        fallbackMessage: 'Failed to mark notifications as read',
      );
    }
  }

  @override
  Future<int> markAllAsRead() async {
    try {
      final response = await dio.post(AppConstants.markAllReadEndpoint);

      final data = _extractData(
        response,
        fallbackMessage: 'Failed to mark all notifications as read',
      );

      return data['updated_count'] as int? ?? 0;
    } on DioException catch (e) {
      throw _handleDioException(
        e,
        fallbackMessage: 'Failed to mark all notifications as read',
      );
    }
  }

  dynamic _extractData(
    Response<dynamic> response, {
    required String fallbackMessage,
  }) {
    final payload = response.data;
    if (payload is! Map<String, dynamic>) {
      throw ServerException('Invalid response format');
    }

    final success = payload['success'] == true;
    final statusCode = response.statusCode ?? 500;
    if (statusCode >= 200 && statusCode < 300 && success) {
      return payload['data'];
    }

    final message = payload['message']?.toString() ?? fallbackMessage;
    final code = payload['code'] is int ? payload['code'] as int : statusCode;
    throw ServerException(message, code: code);
  }

  ServerException _handleDioException(
    DioException exception, {
    required String fallbackMessage,
  }) {
    final data = exception.response?.data;
    if (data is Map<String, dynamic>) {
      final message = data['message']?.toString() ??
          data['detail']?.toString() ??
          fallbackMessage;
      final code = data['code'] is int
          ? data['code'] as int
          : exception.response?.statusCode ?? 500;
      return ServerException(message, code: code);
    }
    return ServerException(
      fallbackMessage,
      code: exception.response?.statusCode ?? 500,
    );
  }
}
