import 'package:equatable/equatable.dart';
import 'notification.dart';

class NotificationListResponse extends Equatable {
  final List<Notification> notifications;
  final int totalCount;
  final int unreadCount;

  const NotificationListResponse({
    required this.notifications,
    required this.totalCount,
    required this.unreadCount,
  });

  @override
  List<Object?> get props => [notifications, totalCount, unreadCount];
}
