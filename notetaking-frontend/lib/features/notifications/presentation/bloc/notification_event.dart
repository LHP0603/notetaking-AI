import 'package:equatable/equatable.dart';

abstract class NotificationEvent extends Equatable {
  const NotificationEvent();

  @override
  List<Object?> get props => [];
}

class LoadNotifications extends NotificationEvent {
  const LoadNotifications();
}

class LoadMoreUnread extends NotificationEvent {
  const LoadMoreUnread();
}

class LoadMoreRead extends NotificationEvent {
  const LoadMoreRead();
}

class MarkNotificationAsRead extends NotificationEvent {
  final int notificationId;

  const MarkNotificationAsRead(this.notificationId);

  @override
  List<Object?> get props => [notificationId];
}

class MarkAllAsRead extends NotificationEvent {
  const MarkAllAsRead();
}

class RefreshNotifications extends NotificationEvent {
  const RefreshNotifications();
}
