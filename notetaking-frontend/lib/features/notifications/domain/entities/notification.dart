import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart' show Color, Colors, IconData, Icons;

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

  Notification copyWith({
    int? id,
    int? userId,
    String? title,
    String? body,
    NotificationType? type,
    int? relatedId,
    Map<String, dynamic>? data,
    bool? isRead,
    DateTime? readAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Notification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      relatedId: relatedId ?? this.relatedId,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

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
