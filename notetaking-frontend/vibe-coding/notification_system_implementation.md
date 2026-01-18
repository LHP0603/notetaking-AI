# Notification System Implementation Guide

## Overview
This guide describes the complete implementation of the notification system in the Voicely app, including UI components, data layer, and navigation flow.

## UI Requirements

### Main Notification Screen
- **Navigation Item**: Index 3 (change icon to bell/notification)
- **AppBar**: Similar to other screens with "Notifications" title
- **Body Layout**: Vertical list with two main sections:
  1. Unread Notifications
  2. Read Notifications
- **Display Limit**: Maximum 3 most recent notifications per section
- **See All Button**: Show next to section title if more than 3 notifications exist

### Notification List Screen
- **AppBar Title**: "Unread Notifications" or "Read Notifications"
- **AppBar Action**: "Mark All Read" button
- **Body**: Full list of notifications with pagination
- **Empty State**: Show when no notifications exist

### Notification Detail Screen
- **AppBar Title**: "Notification Detail"
- **Body**: Full notification content with action buttons
- **Auto-mark Read**: Automatically mark as read when opened

## API Endpoints

### 1. Get Notifications List
```
GET /api/v1/notifications/
```

#### Query Parameters
```dart
{
  "is_read": bool?,           // Filter by read status
  "notification_type": String?, // Filter by type
  "skip": int?,               // Pagination offset (default: 0)
  "limit": int?,              // Items per page (default: 20, max: 100)
}
```

#### Response
```json
{
  "success": true,
  "code": 200,
  "message": "Notifications retrieved successfully",
  "data": {
    "notifications": [
      {
        "id": 1,
        "user_id": 2,
        "title": "Transcription Complete ✅",
        "body": "Your audio 'meeting.m4a' has been transcribed successfully",
        "notification_type": "transcription_complete",
        "related_id": 30,
        "data": {
          "type": "transcription_complete",
          "audio_id": "30",
          "status": "completed"
        },
        "is_read": false,
        "read_at": null,
        "created_at": "2025-12-27T10:30:00Z",
        "updated_at": "2025-12-27T10:30:00Z"
      }
    ],
    "total_count": 15,
    "unread_count": 5
  }
}
```

### 2. Get Unread Count
```
GET /api/v1/notifications/unread-count
```

#### Response
```json
{
  "success": true,
  "code": 200,
  "message": "Unread count retrieved successfully",
  "data": {
    "unread_count": 5
  }
}
```

### 3. Get Notification Detail
```
GET /api/v1/notifications/{notification_id}
```

#### Path Parameters
- `notification_id`: int - ID of the notification

#### Response
```json
{
  "success": true,
  "code": 200,
  "message": "Notification retrieved successfully",
  "data": {
    "id": 1,
    "user_id": 2,
    "title": "Summary Ready 📝",
    "body": "Your note has been summarized",
    "notification_type": "summarization_complete",
    "related_id": 12,
    "data": {
      "type": "summarization_complete",
      "audio_id": "30",
      "note_id": "12",
      "status": "completed"
    },
    "is_read": false,
    "read_at": null,
    "created_at": "2025-12-27T10:30:00Z",
    "updated_at": "2025-12-27T10:30:00Z"
  }
}
```

#### Error Response (404)
```json
{
  "success": false,
  "code": 404,
  "message": "Notification not found"
}
```

### 4. Mark Notifications as Read
```
POST /api/v1/notifications/mark-read
```

#### Request Body
```json
{
  "notification_ids": [1, 2, 3]
}
```

#### Response
```json
{
  "success": true,
  "code": 200,
  "message": "Marked 3 notification(s) as read",
  "data": {
    "updated_count": 3
  }
}
```

### 5. Mark All Notifications as Read
```
POST /api/v1/notifications/mark-all-read
```

#### Request Body
No body required

#### Response
```json
{
  "success": true,
  "code": 200,
  "message": "Marked all 5 notification(s) as read",
  "data": {
    "updated_count": 5
  }
}
```

## Notification Types

| Type | Description | Related ID |
|------|-------------|------------|
| `transcription_complete` | Transcription completed | audio_id |
| `transcription_failed` | Transcription failed | audio_id |
| `summarization_complete` | Summary created | note_id |
| `summarization_failed` | Summary failed | audio_id |
| `audio_processed` | Audio processing complete | audio_id |
| `note_created` | Note created | note_id |
| `task_completed` | Task completed | task_id |
| `task_failed` | Task failed | task_id |
| `folder_shared` | Folder shared | folder_id |
| `system_announcement` | System announcement | null |

## Data Models

### Notification Entity
```dart
import 'package:equatable/equatable.dart';

class Notification extends Equatable {
  final int id;
  final int userId;
  final String title;
  final String body;
  final NotificationType type;
  final int? relatedId;
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Notification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.relatedId,
    this.data,
    required this.isRead,
    this.readAt,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
    id,
    userId,
    title,
    body,
    type,
    relatedId,
    data,
    isRead,
    readAt,
    createdAt,
    updatedAt,
  ];
}
```

### NotificationType Enum
```dart
enum NotificationType {
  transcriptionComplete('transcription_complete'),
  transcriptionFailed('transcription_failed'),
  summarizationComplete('summarization_complete'),
  summarizationFailed('summarization_failed'),
  audioProcessed('audio_processed'),
  noteCreated('note_created'),
  taskCompleted('task_completed'),
  taskFailed('task_failed'),
  folderShared('folder_shared'),
  systemAnnouncement('system_announcement');

  const NotificationType(this.value);
  final String value;

  static NotificationType fromString(String value) {
    return NotificationType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => NotificationType.systemAnnouncement,
    );
  }

  IconData get icon {
    switch (this) {
      case NotificationType.transcriptionComplete:
        return Icons.mic_rounded;
      case NotificationType.transcriptionFailed:
        return Icons.error_outline;
      case NotificationType.summarizationComplete:
        return Icons.summarize;
      case NotificationType.summarizationFailed:
        return Icons.error_outline;
      case NotificationType.audioProcessed:
        return Icons.audio_file;
      case NotificationType.noteCreated:
        return Icons.note_add;
      case NotificationType.taskCompleted:
        return Icons.check_circle;
      case NotificationType.taskFailed:
        return Icons.error;
      case NotificationType.folderShared:
        return Icons.folder_shared;
      case NotificationType.systemAnnouncement:
        return Icons.notifications;
    }
  }

  Color get color {
    switch (this) {
      case NotificationType.transcriptionComplete:
      case NotificationType.summarizationComplete:
      case NotificationType.taskCompleted:
        return Colors.green;
      case NotificationType.transcriptionFailed:
      case NotificationType.summarizationFailed:
      case NotificationType.taskFailed:
        return Colors.red;
      case NotificationType.audioProcessed:
      case NotificationType.noteCreated:
        return const Color(0xFF3B82F6);
      case NotificationType.folderShared:
        return Colors.amber;
      case NotificationType.systemAnnouncement:
        return Colors.grey;
    }
  }
}
```

### NotificationModel
```dart
import '../../domain/entities/notification.dart';
import 'dart:convert';

class NotificationModel extends Notification {
  const NotificationModel({
    required super.id,
    required super.userId,
    required super.title,
    required super.body,
    required super.type,
    super.relatedId,
    super.data,
    required super.isRead,
    super.readAt,
    required super.createdAt,
    required super.updatedAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      title: json['title'] as String,
      body: json['body'] as String,
      type: NotificationType.fromString(json['notification_type'] as String),
      relatedId: json['related_id'] as int?,
      data: json['data'] as Map<String, dynamic>?,
      isRead: json['is_read'] as bool,
      readAt: json['read_at'] != null 
        ? DateTime.parse(json['read_at'] as String) 
        : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'body': body,
      'notification_type': type.value,
      'related_id': relatedId,
      'data': data,
      'is_read': isRead,
      'read_at': readAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
```

### NotificationListResponse
```dart
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
```

## Constants

Add to `AppConstants`:

```dart
// Notification endpoints
static const String notificationsEndpoint = '/api/v1/notifications/';
static const String unreadCountEndpoint = '/api/v1/notifications/unread-count';
static const String markReadEndpoint = '/api/v1/notifications/mark-read';
static const String markAllReadEndpoint = '/api/v1/notifications/mark-all-read';
static String notificationById(int id) => '/api/v1/notifications/$id';

// Notification settings
static const int notificationsPerPage = 20;
static const int maxNotificationsPerPage = 100;
static const int previewNotificationsLimit = 3;
```

## Repository Layer

### NotificationRepository Interface
```dart
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
```

### NotificationRemoteDataSource
```dart
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
```

### Implementation Example
```dart
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
        totalCount: data['total_count'] as int,
        unreadCount: data['unread_count'] as int,
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

      return data['unread_count'] as int;
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

      return data['updated_count'] as int;
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

      return data['updated_count'] as int;
    } on DioException catch (e) {
      throw _handleDioException(
        e,
        fallbackMessage: 'Failed to mark all notifications as read',
      );
    }
  }

  // Helper methods (similar to AudioManagerRemoteDataSource)
  dynamic _extractData(Response response, {required String fallbackMessage}) {
    // Implementation similar to existing data sources
  }

  ServerException _handleDioException(DioException exception, {required String fallbackMessage}) {
    // Implementation similar to existing data sources
  }
}
```

## State Management

### Notification State
```dart
class NotificationState extends Equatable {
  final List<Notification> unreadNotifications;
  final List<Notification> readNotifications;
  final int unreadCount;
  final bool isLoading;
  final String? error;
  final bool hasMoreUnread;
  final bool hasMoreRead;

  const NotificationState({
    this.unreadNotifications = const [],
    this.readNotifications = const [],
    this.unreadCount = 0,
    this.isLoading = false,
    this.error,
    this.hasMoreUnread = true,
    this.hasMoreRead = true,
  });

  NotificationState copyWith({
    List<Notification>? unreadNotifications,
    List<Notification>? readNotifications,
    int? unreadCount,
    bool? isLoading,
    String? error,
    bool? hasMoreUnread,
    bool? hasMoreRead,
  }) {
    return NotificationState(
      unreadNotifications: unreadNotifications ?? this.unreadNotifications,
      readNotifications: readNotifications ?? this.readNotifications,
      unreadCount: unreadCount ?? this.unreadCount,
      isLoading: isLoading ?? this.isLoading,
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
    isLoading,
    error,
    hasMoreUnread,
    hasMoreRead,
  ];
}
```

### Notification Events
```dart
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
```

## UI Components

### Main Notification Screen
```dart
class NotificationScreen extends StatefulWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    context.read<NotificationBloc>().add(const LoadNotifications());
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
          if (state.isLoading && state.unreadNotifications.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.error != null && state.unreadNotifications.isEmpty) {
            return _buildErrorState(state.error!);
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<NotificationBloc>().add(const RefreshNotifications());
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  _buildNotificationSection(
                    title: 'Unread',
                    notifications: state.unreadNotifications.take(3).toList(),
                    showSeeAll: state.unreadNotifications.length > 3,
                    onSeeAll: () => _navigateToList(context, isRead: false),
                    emptyMessage: 'No unread notifications',
                  ),
                  const SizedBox(height: 16),
                  _buildNotificationSection(
                    title: 'Read',
                    notifications: state.readNotifications.take(3).toList(),
                    showSeeAll: state.readNotifications.length > 3,
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
            ...notifications.map((notification) => 
              NotificationCard(
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
    // Mark as read if unread
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
```

### Notification Card Widget
```dart
class NotificationCard extends StatelessWidget {
  final Notification notification;
  final VoidCallback onTap;

  const NotificationCard({
    Key? key,
    required this.notification,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: notification.isRead ? Colors.grey[100] : Colors.white,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: notification.type.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  notification.type.icon,
                  color: notification.type.color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontWeight: notification.isRead 
                                ? FontWeight.normal 
                                : FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(left: 8),
                            decoration: const BoxDecoration(
                              color: Color(0xFF3B82F6),
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatTimestamp(notification.createdAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Chevron
              Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}
```

### Notification List Screen
```dart
class NotificationListScreen extends StatefulWidget {
  final bool isRead;

  const NotificationListScreen({
    Key? key,
    required this.isRead,
  }) : super(key: key);

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
          final notifications = widget.isRead 
            ? state.readNotifications 
            : state.unreadNotifications;

          if (state.isLoading && notifications.isEmpty) {
            return const Center(child: CircularProgressIndicator());
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
            itemCount: notifications.length + (state.isLoading ? 1 : 0),
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
```

### Notification Detail Screen
```dart
class NotificationDetailScreen extends StatelessWidget {
  final Notification notification;

  const NotificationDetailScreen({
    Key? key,
    required this.notification,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101822),
      appBar: AppBar(
        backgroundColor: const Color(0xFF101822),
        elevation: 0,
        title: const Text('Notification Detail'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon and type
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: notification.type.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    notification.type.icon,
                    color: notification.type.color,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatTimestamp(notification.createdAt),
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Body
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                notification.body,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Action buttons based on type
            if (notification.relatedId != null)
              _buildActionButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context) {
    String buttonText;
    VoidCallback onPressed;

    switch (notification.type) {
      case NotificationType.transcriptionComplete:
      case NotificationType.audioProcessed:
        buttonText = 'View Audio';
        onPressed = () => _navigateToAudio(context, notification.relatedId!);
        break;
      case NotificationType.summarizationComplete:
      case NotificationType.noteCreated:
        buttonText = 'View Note';
        onPressed = () => _navigateToNote(context, notification.relatedId!);
        break;
      default:
        return const SizedBox.shrink();
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF3B82F6),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: Text(buttonText),
      ),
    );
  }

  void _navigateToAudio(BuildContext context, int audioId) {
    // Navigate to audio detail screen
    // Implementation similar to chatbot references
  }

  void _navigateToNote(BuildContext context, int noteId) {
    // Navigate to note/summary screen
  }

  String _formatTimestamp(DateTime timestamp) {
    return '${timestamp.day}/${timestamp.month}/${timestamp.year} at ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
  }
}
```

## Bottom Navigation Update

Update the main navigation to include notification icon:

```dart
// In main navigation screen
BottomNavigationBarItem(
  icon: Stack(
    children: [
      const Icon(Icons.notifications),
      if (unreadCount > 0)
        Positioned(
          right: 0,
          top: 0,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
            constraints: const BoxConstraints(
              minWidth: 16,
              minHeight: 16,
            ),
            child: Text(
              unreadCount > 99 ? '99+' : '$unreadCount',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
    ],
  ),
  label: 'Notifications',
),
```

## Implementation Checklist

### Phase 1: Setup (Data Layer)
- [ ] Create notification feature folder structure
- [ ] Add API endpoints to `AppConstants`
- [ ] Create `NotificationType` enum with icons and colors
- [ ] Create `Notification` entity
- [ ] Create `NotificationModel` with `fromJson`/`toJson`
- [ ] Create `NotificationListResponse` entity
- [ ] Create `NotificationRepository` interface
- [ ] Create `NotificationRemoteDataSource` interface

### Phase 2: Data Source & Repository Implementation
- [ ] Implement `NotificationRemoteDataSourceImpl`
- [ ] Implement `getNotifications()` method
- [ ] Implement `getUnreadCount()` method
- [ ] Implement `getNotificationById()` method
- [ ] Implement `markAsRead()` method
- [ ] Implement `markAllAsRead()` method
- [ ] Implement `NotificationRepositoryImpl` with error handling
- [ ] Add dependency injection for notification repository

### Phase 3: State Management
- [ ] Create `NotificationState` class
- [ ] Create `NotificationEvent` classes
- [ ] Create `NotificationBloc`
- [ ] Implement `LoadNotifications` event handler
- [ ] Implement `MarkAsRead` event handler
- [ ] Implement `MarkAllAsRead` event handler
- [ ] Implement pagination logic
- [ ] Add refresh functionality

### Phase 4: UI Components
- [ ] Create `NotificationScreen` (main screen)
- [ ] Create `NotificationCard` widget
- [ ] Create `NotificationListScreen` (full list)
- [ ] Create `NotificationDetailScreen`
- [ ] Implement section headers with "See All" buttons
- [ ] Add empty states for each section
- [ ] Add loading indicators
- [ ] Add error states with retry

### Phase 5: Navigation & Integration
- [ ] Update bottom navigation bar with bell icon
- [ ] Add unread count badge to navigation icon
- [ ] Implement navigation to audio detail from notifications
- [ ] Implement navigation to note detail from notifications
- [ ] Add pull-to-refresh on main screen
- [ ] Add infinite scroll on list screen
- [ ] Test all navigation flows

### Phase 6: Polish & Testing
- [ ] Add animations for cards
- [ ] Implement haptic feedback
- [ ] Add accessibility labels
- [ ] Test with different notification types
- [ ] Test pagination
- [ ] Test mark as read functionality
- [ ] Test mark all as read
- [ ] Test empty states
- [ ] Test error handling
- [ ] Performance testing with large lists

## Best Practices

1. **Caching**: Cache notifications locally for offline viewing
2. **Real-time Updates**: Consider implementing WebSocket for real-time notifications
3. **Performance**: Use pagination to avoid loading too many notifications
4. **User Experience**: Show optimistic updates when marking as read
5. **Accessibility**: Add semantic labels for screen readers
6. **Error Handling**: Gracefully handle network errors with retry options
7. **State Management**: Keep unread count in sync across app

## Future Enhancements

1. **Push Notifications**: Integrate Firebase Cloud Messaging
2. **Notification Settings**: Allow users to customize notification preferences
3. **Grouping**: Group notifications by date or type
4. **Swipe Actions**: Swipe to mark as read/delete
5. **Search**: Add search functionality for notifications
6. **Filters**: Filter by notification type
7. **Archive**: Archive old notifications
8. **Sound/Vibration**: Custom notification sounds
