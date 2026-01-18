import 'package:equatable/equatable.dart';
import '../../domain/entities/notification.dart';

class NotificationState extends Equatable {
  final List<Notification> unreadNotifications;
  final List<Notification> readNotifications;
  final int unreadCount;
  final int unreadTotalCount;
  final int readTotalCount;
  final int unreadSkip;
  final int readSkip;
  final bool isLoading;
  final bool isLoadingMoreUnread;
  final bool isLoadingMoreRead;
  final String? error;
  final bool hasMoreUnread;
  final bool hasMoreRead;

  const NotificationState({
    this.unreadNotifications = const [],
    this.readNotifications = const [],
    this.unreadCount = 0,
    this.unreadTotalCount = 0,
    this.readTotalCount = 0,
    this.unreadSkip = 0,
    this.readSkip = 0,
    this.isLoading = false,
    this.isLoadingMoreUnread = false,
    this.isLoadingMoreRead = false,
    this.error,
    this.hasMoreUnread = true,
    this.hasMoreRead = true,
  });

  factory NotificationState.initial() => const NotificationState();

  NotificationState copyWith({
    List<Notification>? unreadNotifications,
    List<Notification>? readNotifications,
    int? unreadCount,
    int? unreadTotalCount,
    int? readTotalCount,
    int? unreadSkip,
    int? readSkip,
    bool? isLoading,
    bool? isLoadingMoreUnread,
    bool? isLoadingMoreRead,
    String? error,
    bool? hasMoreUnread,
    bool? hasMoreRead,
  }) {
    return NotificationState(
      unreadNotifications: unreadNotifications ?? this.unreadNotifications,
      readNotifications: readNotifications ?? this.readNotifications,
      unreadCount: unreadCount ?? this.unreadCount,
      unreadTotalCount: unreadTotalCount ?? this.unreadTotalCount,
      readTotalCount: readTotalCount ?? this.readTotalCount,
      unreadSkip: unreadSkip ?? this.unreadSkip,
      readSkip: readSkip ?? this.readSkip,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMoreUnread:
          isLoadingMoreUnread ?? this.isLoadingMoreUnread,
      isLoadingMoreRead: isLoadingMoreRead ?? this.isLoadingMoreRead,
      error: error,
      hasMoreUnread: hasMoreUnread ?? this.hasMoreUnread,
      hasMoreRead: hasMoreRead ?? this.hasMoreRead,
    );
  }

  @override
  List<Object?> get props => [
    unreadNotifications,
    readNotifications,
    unreadCount,
    unreadTotalCount,
    readTotalCount,
    unreadSkip,
    readSkip,
    isLoading,
    isLoadingMoreUnread,
    isLoadingMoreRead,
    error,
    hasMoreUnread,
    hasMoreRead,
  ];
}
