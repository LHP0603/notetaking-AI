import 'package:equatable/equatable.dart';

// Local recording session states 
enum LocalRecordingState { idle, recording, paused, completed }

enum RecordingStatus {
  uploading('UPLOADING'),
  processed('PROCESSED'),
  error('ERROR');

  final String value;
  const RecordingStatus(this.value);

  static RecordingStatus fromString(String value) {
    return RecordingStatus.values.firstWhere(
      (status) => status.value == value.toUpperCase(),
      orElse: () => RecordingStatus.uploading,
    );
  }
}

enum SourceType {
  recorded('RECORDED'),
  imported('IMPORTED');

  final String value;
  const SourceType(this.value);

  static SourceType fromString(String value) {
    return SourceType.values.firstWhere(
      (type) => type.value == value.toUpperCase(),
      orElse: () => SourceType.recorded,
    );
  }
}

class Recording extends Equatable {
  final String recordingId; // uuid recording_id PK
  final String userId; // uuid user_id FK
  final String? folderId; // uuid folder_id FK
  final String title;
  final String filePath; // Đường dẫn file trên Cloud/Local
  final double durationSeconds;
  final double fileSizeMb;
  final RecordingStatus status; // Enum: UPLOADING, PROCESSED, ERROR
  final SourceType sourceType; // RECORDED or IMPORTED
  final bool isPinned;
  final bool isTrashed; // Soft delete flag
  final String? originalFileName;
  final double? lastPlayPosition; // Last playback position in seconds
  final DateTime createdAt;
  final DateTime? deletedAt; // Hỗ trợ Soft Delete (Thùng rác)

  const Recording({
    required this.recordingId,
    required this.userId,
    this.folderId,
    required this.title,
    required this.filePath,
    required this.durationSeconds,
    required this.fileSizeMb,
    required this.status,
    required this.sourceType,
    required this.isPinned,
    required this.isTrashed,
    this.originalFileName,
    this.lastPlayPosition,
    required this.createdAt,
    this.deletedAt,
  });

  Recording copyWith({
    String? recordingId,
    String? userId,
    String? folderId,
    String? title,
    String? filePath,
    double? durationSeconds,
    double? fileSizeMb,
    RecordingStatus? status,
    SourceType? sourceType,
    bool? isPinned,
    bool? isTrashed,
    String? originalFileName,
    double? lastPlayPosition,
    DateTime? createdAt,
    DateTime? deletedAt,
  }) {
    return Recording(
      recordingId: recordingId ?? this.recordingId,
      userId: userId ?? this.userId,
      folderId: folderId ?? this.folderId,
      title: title ?? this.title,
      filePath: filePath ?? this.filePath,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      fileSizeMb: fileSizeMb ?? this.fileSizeMb,
      status: status ?? this.status,
      sourceType: sourceType ?? this.sourceType,
      isPinned: isPinned ?? this.isPinned,
      isTrashed: isTrashed ?? this.isTrashed,
      originalFileName: originalFileName ?? this.originalFileName,
      lastPlayPosition: lastPlayPosition ?? this.lastPlayPosition,
      createdAt: createdAt ?? this.createdAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  List<Object?> get props => [
    recordingId,
    userId,
    folderId,
    title,
    filePath,
    durationSeconds,
    fileSizeMb,
    status,
    sourceType,
    isPinned,
    isTrashed,
    originalFileName,
    lastPlayPosition,
    createdAt,
    deletedAt,
  ];
}












