import '../../domain/entities/recording.dart';

class RecordingModel extends Recording {
  const RecordingModel({
    super.id,
    super.filePath,
    super.fileName,
    super.duration,
    super.createdAt,
    super.status,
  });

  factory RecordingModel.fromEntity(Recording recording) {
    return RecordingModel(
      id: recording.id,
      filePath: recording.filePath,
      fileName: recording.fileName,
      duration: recording.duration,
      createdAt: recording.createdAt,
      status: recording.status,
    );
  }

  factory RecordingModel.fromJson(Map<String, dynamic> json) {
    return RecordingModel(
      id: json['id'] as String?,
      filePath: json['file_path'] as String?,
      fileName: json['file_name'] as String?,
      duration: Duration(milliseconds: json['duration_ms'] as int? ?? 0),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      status: RecordingStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => RecordingStatus.idle,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'file_path': filePath,
      'file_name': fileName,
      'duration_ms': duration.inMilliseconds,
      'created_at': createdAt?.toIso8601String(),
      'status': status.name,
    };
  }
}





