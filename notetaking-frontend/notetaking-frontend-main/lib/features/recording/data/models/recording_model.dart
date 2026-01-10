import '../../domain/entities/recording.dart';

class RecordingModel extends Recording {
  const RecordingModel({
    required String recordingId,
    required String userId,
    String? folderId,
    required String title,
    required String filePath,
    required double durationSeconds,
    required double fileSizeMb,
    required RecordingStatus status,
    required SourceType sourceType,
    required bool isPinned,
    required bool isTrashed,
    String? originalFileName,
    double? lastPlayPosition,
    required DateTime createdAt,
    DateTime? deletedAt,
  }) : super(
         recordingId: recordingId,
         userId: userId,
         folderId: folderId,
         title: title,
         filePath: filePath,
         durationSeconds: durationSeconds,
         fileSizeMb: fileSizeMb,
         status: status,
         sourceType: sourceType,
         isPinned: isPinned,
         isTrashed: isTrashed,
         originalFileName: originalFileName,
         lastPlayPosition: lastPlayPosition,
         createdAt: createdAt,
         deletedAt: deletedAt,
       );

  factory RecordingModel.fromEntity(Recording recording) {
    return RecordingModel(
      recordingId: recording.recordingId,
      userId: recording.userId,
      folderId: recording.folderId,
      title: recording.title,
      filePath: recording.filePath,
      durationSeconds: recording.durationSeconds,
      fileSizeMb: recording.fileSizeMb,
      status: recording.status,
      sourceType: recording.sourceType,
      isPinned: recording.isPinned,
      isTrashed: recording.isTrashed,
      originalFileName: recording.originalFileName,
      lastPlayPosition: recording.lastPlayPosition,
      createdAt: recording.createdAt,
      deletedAt: recording.deletedAt,
    );
  }

  factory RecordingModel.fromJson(Map<String, dynamic> json) {
    return RecordingModel(
      recordingId: json['recording_id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      folderId: json['folder_id'] as String?,
      title: json['title'] as String? ?? '',
      // file_path, duration_seconds, and file_size_mb can be null when recording is first created
      filePath: json['file_path'] as String? ?? '',
      durationSeconds: json['duration_seconds'] != null
          ? (json['duration_seconds'] as num).toDouble()
          : 0.0,
      fileSizeMb: json['file_size_mb'] != null
          ? (json['file_size_mb'] as num).toDouble()
          : 0.0,
      status: RecordingStatus.fromString(
        json['status'] as String? ?? 'UPLOADING',
      ),
      sourceType: SourceType.fromString(
        json['source_type'] as String? ?? 'RECORDED',
      ),
      isPinned: json['is_pinned'] as bool? ?? false,
      isTrashed: json['is_trashed'] as bool? ?? false,
      originalFileName: json['original_file_name'] as String?,
      lastPlayPosition:
          json['last_play_position'] != null
              ? (json['last_play_position'] as num).toDouble()
              : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      deletedAt:
          json['deleted_at'] != null
              ? DateTime.parse(json['deleted_at'] as String)
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'recording_id': recordingId,
      'user_id': userId,
      'folder_id': folderId,
      'title': title,
      'file_path': filePath,
      'duration_seconds': durationSeconds,
      'file_size_mb': fileSizeMb,
      'status': status.value,
      'source_type': sourceType.value,
      'is_pinned': isPinned,
      'is_trashed': isTrashed,
      'original_file_name': originalFileName,
      'last_play_position': lastPlayPosition,
      'created_at': createdAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }
}






