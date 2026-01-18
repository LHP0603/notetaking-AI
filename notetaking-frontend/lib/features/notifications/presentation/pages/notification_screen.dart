import 'package:flutter/material.dart' hide Notification;
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/notification.dart';
import '../bloc/notification_bloc.dart';
import '../bloc/notification_event.dart';
import '../bloc/notification_state.dart';
import '../widgets/notification_card.dart';
import 'notification_detail_screen.dart';
import 'notification_list_screen.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    final bloc = context.read<NotificationBloc>();
    final state = bloc.state;
    if (state.unreadNotifications.isEmpty &&
        state.readNotifications.isEmpty &&
        !state.isLoading) {
      bloc.add(const LoadNotifications());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101822),
      appBar: AppBar(
        backgroundColor: const Color(0xFF101822),
        elevation: 0,
        title: const Text('Notifications'),
      ),
      body: BlocBuilder<NotificationBloc, NotificationState>(
        builder: (context, state) {
          if (state.isLoading &&
              state.unreadNotifications.isEmpty &&
              state.readNotifications.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.error != null &&
              state.unreadNotifications.isEmpty &&
              state.readNotifications.isEmpty) {
            return _buildErrorState(state.error!);
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<NotificationBloc>().add(
                const RefreshNotifications(),
              );
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  _buildNotificationSection(
                    title: 'Unread',
                    notifications:
                        state.unreadNotifications
                            .take(AppConstants.previewNotificationsLimit)
                            .toList(),
                    showSeeAll:
                        state.unreadTotalCount >
                        AppConstants.previewNotificationsLimit,
                    onSeeAll: () => _navigateToList(context, isRead: false),
                    emptyMessage: 'No unread notifications',
                  ),
                  const SizedBox(height: 16),
                  _buildNotificationSection(
                    title: 'Read',
                    notifications:
                        state.readNotifications
                            .take(AppConstants.previewNotificationsLimit)
                            .toList(),
                    showSeeAll:
                        state.readTotalCount >
                        AppConstants.previewNotificationsLimit,
                    onSeeAll: () => _navigateToList(context, isRead: true),
                    emptyMessage: 'No read notifications',
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotificationSection({
    required String title,
    required List<Notification> notifications,
    required bool showSeeAll,
    required VoidCallback onSeeAll,
    required String emptyMessage,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (showSeeAll)
                TextButton(
                  onPressed: onSeeAll,
                  child: const Text('See All'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (notifications.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  emptyMessage,
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 14,
                  ),
                ),
              ),
            )
          else
            ...notifications.map(
              (notification) => NotificationCard(
                notification: notification,
                onTap: () => _navigateToDetail(context, notification),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
          const SizedBox(height: 16),
          Text(
            error,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              context.read<NotificationBloc>().add(const LoadNotifications());
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _navigateToList(BuildContext context, {required bool isRead}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NotificationListScreen(isRead: isRead),
      ),
    );
  }

  void _navigateToDetail(BuildContext context, Notification notification) {
    if (!notification.isRead) {
      context.read<NotificationBloc>().add(
        MarkNotificationAsRead(notification.id),
      );
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NotificationDetailScreen(
          notification: notification,
        ),
      ),
    );
  }
}
