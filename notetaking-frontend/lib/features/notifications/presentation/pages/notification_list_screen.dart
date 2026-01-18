import 'package:flutter/material.dart' hide Notification;
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/notification.dart';
import '../bloc/notification_bloc.dart';
import '../bloc/notification_event.dart';
import '../bloc/notification_state.dart';
import '../widgets/notification_card.dart';
import 'notification_detail_screen.dart';

class NotificationListScreen extends StatefulWidget {
  final bool isRead;

  const NotificationListScreen({super.key, required this.isRead});

  @override
  State<NotificationListScreen> createState() => _NotificationListScreenState();
}

class _NotificationListScreenState extends State<NotificationListScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      if (widget.isRead) {
        context.read<NotificationBloc>().add(const LoadMoreRead());
      } else {
        context.read<NotificationBloc>().add(const LoadMoreUnread());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101822),
      appBar: AppBar(
        backgroundColor: const Color(0xFF101822),
        elevation: 0,
        title: Text(widget.isRead ? 'Read Notifications' : 'Unread Notifications'),
        actions: [
          if (!widget.isRead)
            TextButton(
              onPressed: () {
                context.read<NotificationBloc>().add(const MarkAllAsRead());
              },
              child: const Text('Mark All Read'),
            ),
        ],
      ),
      body: BlocBuilder<NotificationBloc, NotificationState>(
        builder: (context, state) {
          final notifications =
              widget.isRead
                  ? state.readNotifications
                  : state.unreadNotifications;
          final isLoadingMore =
              widget.isRead
                  ? state.isLoadingMoreRead
                  : state.isLoadingMoreUnread;

          if (state.isLoading && notifications.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.error != null && notifications.isEmpty) {
            return Center(
              child: Text(
                state.error!,
                style: TextStyle(color: Colors.grey[500], fontSize: 16),
                textAlign: TextAlign.center,
              ),
            );
          }

          if (notifications.isEmpty) {
            return Center(
              child: Text(
                widget.isRead
                    ? 'No read notifications'
                    : 'No unread notifications',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 16,
                ),
              ),
            );
          }

          return ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length + (isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= notifications.length) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final notification = notifications[index];
              return NotificationCard(
                notification: notification,
                onTap: () => _navigateToDetail(notification),
              );
            },
          );
        },
      ),
    );
  }

  void _navigateToDetail(Notification notification) {
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
