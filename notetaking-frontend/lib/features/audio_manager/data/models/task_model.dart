import '../../domain/entities/task.dart';

class TaskModel extends Task {
  const TaskModel({
    required super.id,
    required super.taskType,
    required super.status,
    super.result,
    super.errorMessage,
    super.audioId,
    super.metadataJson,
    required super.createdAt,
    required super.updatedAt,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    final metadata = json['metadata_json'];
    return TaskModel(
      id: json['id'] as String,
      taskType: json['task_type'] as String,
      status: json['status'] as String,
      result: json['result'] as String?,
      errorMessage: json['error_message'] as String?,
      audioId: json['audio_id'] as int?,
      metadataJson:
          metadata is Map<String, dynamic>
              ? metadata
              : metadata is Map
              ? metadata.cast<String, dynamic>()
              : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'task_type': taskType,
      'status': status,
      'result': result,
      'error_message': errorMessage,
      'audio_id': audioId,
      'metadata_json': metadataJson,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
