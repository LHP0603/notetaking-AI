import '../../domain/entities/audio_file.dart';

class AudioFileModel extends AudioFile {
  const AudioFileModel({
    required super.id,
    super.userId,
    required super.filename,
    super.originalFilename,
    super.filePath,
    super.fileSize,
    super.duration,
    super.format,
    super.uploadDate,
    super.status,
    super.transcription,
    super.confidenceScore,
    super.createdAt,
    super.updatedAt,
    super.isSummarize,
    super.summary,
    super.transcriptionId,
    super.hasSummary,
  });

  factory AudioFileModel.fromJson(Map<String, dynamic> json) {
    String? _stringFrom(dynamic value) {
      if (value == null) {
        return null;
      }
      return value.toString();
    }

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

    double? _doubleFrom(dynamic value) {
      if (value is double) {
        return value;
      }
      if (value is num) {
        return value.toDouble();
      }
      if (value is String) {
        return double.tryParse(value);
      }
      return null;
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

    final originalFilename =
        _stringFrom(json['original_filename']) ??
        _stringFrom(json['filename']);
    final parsedHasSummary =
        json['has_summary'] as bool? ?? json['is_summarize'] as bool?;
    final parsedIsSummarize =
        json['is_summarize'] as bool? ?? parsedHasSummary;

    return AudioFileModel(
      id: _intFrom(json['id']) ?? 0,
      userId: _intFrom(json['user_id']),
      filename: originalFilename ?? 'Unknown file',
      originalFilename: originalFilename,
      filePath: _stringFrom(json['file_path']),
      fileSize: _intFrom(json['file_size']),
      duration: _doubleFrom(json['duration']),
      format: _stringFrom(json['format']),
      uploadDate: _dateFrom(json['upload_date']) ?? _dateFrom(json['created_at']),
      status: _stringFrom(json['status']),
      transcription: _stringFrom(json['transcription']),
      confidenceScore: _doubleFrom(json['confidence_score']),
      createdAt: _dateFrom(json['created_at']),
      updatedAt: _dateFrom(json['updated_at']),
      isSummarize: parsedIsSummarize,
      summary: _stringFrom(json['summary']),
      transcriptionId: _intFrom(json['transcription_id']),
      hasSummary: parsedHasSummary,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'filename': filename,
      'original_filename': originalFilename,
      'file_path': filePath,
      'file_size': fileSize,
      'duration': duration,
      'format': format,
      'upload_date': uploadDate?.toIso8601String(),
      'status': status,
      'transcription': transcription,
      'confidence_score': confidenceScore,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'is_summarize': isSummarize,
      'summary': summary,
      'transcription_id': transcriptionId,
      'has_summary': hasSummary,
    };
  }
}
