import '../../domain/entities/audio_upload_result.dart';

class AudioUploadResultModel extends AudioUploadResult {
  const AudioUploadResultModel({
    required super.audioId,
    required super.filename,
    required super.filePath,
    required super.taskId,
  });

  factory AudioUploadResultModel.fromJson(Map<String, dynamic> json) {
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

    String _stringFrom(dynamic value, {String fallback = ''}) {
      if (value == null) {
        return fallback;
      }
      return value.toString();
    }

    return AudioUploadResultModel(
      audioId: _intFrom(json['audio_id'] ?? json['id']) ?? 0,
      filename: _stringFrom(
        json['filename'] ?? json['original_filename'],
        fallback: 'Uploaded audio',
      ),
      filePath: _stringFrom(json['file_path']),
      taskId: _stringFrom(json['task_id'] ?? json['job_id']),
    );
  }
}
