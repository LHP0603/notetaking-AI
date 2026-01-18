import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/usecase.dart';
import '../../domain/entities/notification.dart';
import '../../domain/entities/notification_list_response.dart';
import '../../domain/usecases/get_notification_by_id.dart';
import '../../domain/usecases/get_notifications.dart';
import '../../domain/usecases/get_unread_count.dart';
import '../../domain/usecases/mark_all_notifications_as_read.dart';
import '../../domain/usecases/mark_notifications_as_read.dart';
import 'notification_event.dart';
import 'notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final GetNotifications getNotifications;
  final GetUnreadCount getUnreadCount;
  final GetNotificationById getNotificationById;
  final MarkNotificationsAsRead markNotificationsAsRead;
  final MarkAllNotificationsAsRead markAllNotificationsAsRead;

  NotificationBloc({
    required this.getNotifications,
    required this.getUnreadCount,
    required this.getNotificationById,
    required this.markNotificationsAsRead,
    required this.markAllNotificationsAsRead,
  }) : super(NotificationState.initial()) {
    on<LoadNotifications>(_onLoadNotifications);
    on<RefreshNotifications>(_onRefreshNotifications);
    on<LoadMoreUnread>(_onLoadMoreUnread);
    on<LoadMoreRead>(_onLoadMoreRead);
    on<MarkNotificationAsRead>(_onMarkNotificationAsRead);
    on<MarkAllAsRead>(_onMarkAllAsRead);
  }

  Future<void> _onLoadNotifications(
    LoadNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    emit(
      state.copyWith(
        isLoading: true,
        error: null,
        isLoadingMoreUnread: false,
        isLoadingMoreRead: false,
      ),
    );

    final unreadResult = await getNotifications(
      const GetNotificationsParams(
        isRead: false,
        skip: 0,
        limit: AppConstants.notificationsPerPage,
      ),
    );
    final readResult = await getNotifications(
      const GetNotificationsParams(
        isRead: true,
        skip: 0,
        limit: AppConstants.notificationsPerPage,
      ),
    );

    NotificationListResponse? unreadResponse;
    NotificationListResponse? readResponse;
    String? error;

    unreadResult.fold(
      (failure) => error ??= failure.message,
      (response) => unreadResponse = response,
    );

    readResult.fold(
      (failure) => error ??= failure.message,
      (response) => readResponse = response,
    );

    if (unreadResponse == null && readResponse == null) {
      emit(state.copyWith(isLoading: false, error: error));
      return;
    }

    final unreadNotifications =
        unreadResponse?.notifications ?? state.unreadNotifications;
    final readNotifications =
        readResponse?.notifications ?? state.readNotifications;

    final unreadTotalCount =
        unreadResponse?.totalCount ?? state.unreadTotalCount;
    final readTotalCount = readResponse?.totalCount ?? state.readTotalCount;
    final unreadCount = unreadResponse?.unreadCount ??
        readResponse?.unreadCount ??
        state.unreadCount;

    final unreadSkip = unreadResponse != null
        ? unreadNotifications.length
        : state.unreadSkip;
    final readSkip =
        readResponse != null ? readNotifications.length : state.readSkip;

    emit(
      state.copyWith(
        isLoading: false,
        unreadNotifications: unreadNotifications,
        readNotifications: readNotifications,
        unreadTotalCount: unreadTotalCount,
        readTotalCount: readTotalCount,
        unreadCount: unreadCount,
        unreadSkip: unreadSkip,
        readSkip: readSkip,
        hasMoreUnread: unreadSkip < unreadTotalCount,
        hasMoreRead: readSkip < readTotalCount,
        error: error,
      ),
    );
  }

  Future<void> _onRefreshNotifications(
    RefreshNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    await _onLoadNotifications(const LoadNotifications(), emit);
  }

  Future<void> _onLoadMoreUnread(
    LoadMoreUnread event,
    Emitter<NotificationState> emit,
  ) async {
    if (state.isLoading || state.isLoadingMoreUnread || !state.hasMoreUnread) {
      return;
    }

    emit(state.copyWith(isLoadingMoreUnread: true, error: null));

    final result = await getNotifications(
      GetNotificationsParams(
        isRead: false,
        skip: state.unreadSkip,
        limit: AppConstants.notificationsPerPage,
      ),
    );

    result.fold(
      (failure) => emit(
        state.copyWith(isLoadingMoreUnread: false, error: failure.message),
      ),
      (response) {
        final merged = _mergeNotifications(
          state.unreadNotifications,
          response.notifications,
        );
        final newSkip = state.unreadSkip + response.notifications.length;
        emit(
          state.copyWith(
            isLoadingMoreUnread: false,
            unreadNotifications: merged,
            unreadTotalCount: response.totalCount,
            unreadCount: response.unreadCount,
            unreadSkip: newSkip,
            hasMoreUnread: newSkip < response.totalCount,
          ),
        );
      },
    );
  }

  Future<void> _onLoadMoreRead(
    LoadMoreRead event,
    Emitter<NotificationState> emit,
  ) async {
    if (state.isLoading || state.isLoadingMoreRead || !state.hasMoreRead) {
      return;
    }

    emit(state.copyWith(isLoadingMoreRead: true, error: null));

    final result = await getNotifications(
      GetNotificationsParams(
        isRead: true,
        skip: state.readSkip,
        limit: AppConstants.notificationsPerPage,
      ),
    );

    result.fold(
      (failure) => emit(
        state.copyWith(isLoadingMoreRead: false, error: failure.message),
      ),
      (response) {
        final merged = _mergeNotifications(
          state.readNotifications,
          response.notifications,
        );
        final newSkip = state.readSkip + response.notifications.length;
        emit(
          state.copyWith(
            isLoadingMoreRead: false,
            readNotifications: merged,
            readTotalCount: response.totalCount,
            unreadCount: response.unreadCount,
            readSkip: newSkip,
            hasMoreRead: newSkip < response.totalCount,
          ),
        );
      },
    );
  }

  Future<void> _onMarkNotificationAsRead(
    MarkNotificationAsRead event,
    Emitter<NotificationState> emit,
  ) async {
    final index = state.unreadNotifications.indexWhere(
      (item) => item.id == event.notificationId,
    );
    if (index == -1) {
      return;
    }
    final notification = state.unreadNotifications[index];

    final result = await markNotificationsAsRead(
      MarkNotificationsAsReadParams([event.notificationId]),
    );

    result.fold(
      (failure) => emit(state.copyWith(error: failure.message)),
      (_) {
        final updatedNotification = notification.copyWith(
          isRead: true,
          readAt: notification.readAt ?? DateTime.now(),
        );
        final updatedUnread = state.unreadNotifications
            .where((item) => item.id != notification.id)
            .toList();
        final updatedRead = [
          updatedNotification,
          ...state.readNotifications
              .where((item) => item.id != updatedNotification.id),
        ];
        final newUnreadTotalCount =
            state.unreadTotalCount > 0 ? state.unreadTotalCount - 1 : 0;
        final newReadTotalCount = state.readTotalCount + 1;
        final newUnreadCount = state.unreadCount > 0 ? state.unreadCount - 1 : 0;

        emit(
          state.copyWith(
            unreadNotifications: updatedUnread,
            readNotifications: updatedRead,
            unreadTotalCount: newUnreadTotalCount,
            readTotalCount: newReadTotalCount,
            unreadCount: newUnreadCount,
            hasMoreUnread: state.unreadSkip < newUnreadTotalCount,
            hasMoreRead: state.readSkip < newReadTotalCount,
            error: null,
          ),
        );
      },
    );
  }

  Future<void> _onMarkAllAsRead(
    MarkAllAsRead event,
    Emitter<NotificationState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));

    final result = await markAllNotificationsAsRead(NoParams());

    result.fold(
      (failure) => emit(state.copyWith(isLoading: false, error: failure.message)),
      (_) => add(const LoadNotifications()),
    );
  }

  List<Notification> _mergeNotifications(
    List<Notification> existing,
    List<Notification> incoming,
  ) {
    final merged = [...existing];
    for (final notification in incoming) {
      final index = merged.indexWhere((item) => item.id == notification.id);
      if (index == -1) {
        merged.add(notification);
      } else {
        merged[index] = notification;
      }
    }
    return merged;
  }
}
