import '../../domain/entities/notification.dart';

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
    int? _intFrom(dynamic value) {
      if (value is int) {
        return value;
      }
      if (value is num) {
        return value.toInt();
      }
      if (value is String) {
        return int.tryParse(value);
      }
      return null;
    }

    bool _boolFrom(dynamic value) {
      if (value is bool) {
        return value;
      }
      if (value is num) {
        return value != 0;
      }
      if (value is String) {
        return value.toLowerCase() == 'true' || value == '1';
      }
      return false;
    }

    DateTime? _dateFrom(dynamic value) {
      if (value == null) {
        return null;
      }
      if (value is DateTime) {
        return value;
      }
      return DateTime.tryParse(value.toString());
    }

    Map<String, dynamic>? _mapFrom(dynamic value) {
      if (value is Map<String, dynamic>) {
        return value;
      }
      return null;
    }

    final createdAt = _dateFrom(json['created_at']) ?? DateTime.now();
    final updatedAt = _dateFrom(json['updated_at']) ?? createdAt;

    return NotificationModel(
      id: _intFrom(json['id']) ?? 0,
      userId: _intFrom(json['user_id']) ?? 0,
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      type: NotificationType.fromString(
        json['notification_type']?.toString() ?? '',
      ),
      relatedId: _intFrom(json['related_id']),
      data: _mapFrom(json['data']),
      isRead: _boolFrom(json['is_read']),
      readAt: _dateFrom(json['read_at']),
      createdAt: createdAt,
      updatedAt: updatedAt,
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
