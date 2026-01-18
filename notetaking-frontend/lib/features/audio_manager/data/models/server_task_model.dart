import '../../domain/entities/server_task.dart';

class ServerTaskModel extends ServerTask {
  const ServerTaskModel({
    required super.type,
    required super.taskId,
    required super.filename,
    required super.status,
    super.progress,
    super.startedAt,
    super.audioId,
    super.transcriptionId,
  });

  factory ServerTaskModel.fromJson(
    Map<String, dynamic> json, {
    required ServerTaskType type,
  }) {
    return ServerTaskModel(
      type: type,
      taskId: json['task_id'] as String,
      filename: json['filename'] as String,
      status: json['status'] as String? ?? _defaultStatus(type),
      progress: json['progress'] as int?,
      startedAt:
          json['started_at'] != null
              ? DateTime.parse(json['started_at'] as String)
              : null,
      audioId: json['audio_id'] as int?,
      transcriptionId: json['transcription_id'] as int?,
    );
  }

  static String _defaultStatus(ServerTaskType type) {
    switch (type) {
      case ServerTaskType.uploading:
        return 'uploading';
      case ServerTaskType.transcribing:
        return 'transcribing';
      case ServerTaskType.summarizing:
        return 'summarizing';
    }
  }
}
