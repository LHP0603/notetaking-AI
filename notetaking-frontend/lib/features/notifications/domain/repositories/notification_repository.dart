import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/notification.dart';
import '../entities/notification_list_response.dart';

abstract class NotificationRepository {
  Future<Either<Failure, NotificationListResponse>> getNotifications({
    bool? isRead,
    String? notificationType,
    int skip = 0,
    int limit = 20,
  });

  Future<Either<Failure, int>> getUnreadCount();

  Future<Either<Failure, Notification>> getNotificationById(int id);

  Future<Either<Failure, int>> markAsRead(List<int> notificationIds);

  Future<Either<Failure, int>> markAllAsRead();
}
