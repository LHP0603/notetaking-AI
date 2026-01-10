import '../../domain/entities/export_job.dart';

class ExportJobModel extends ExportJob {
  const ExportJobModel({
    required super.exportId,
    required super.userId,
    required super.recordingId,
    required super.exportType,
    required super.status,
    super.filePath,
    super.downloadUrl,
    super.createdAt,
    super.completedAt,
  });

  factory ExportJobModel.fromJson(Map<String, dynamic> json) {
    return ExportJobModel(
      exportId: json['export_id'],
      userId: json['user_id'],
      recordingId: json['recording_id'],
      exportType: json['export_type'],
      status: json['status'],
      filePath: json['file_path'],
      downloadUrl: json['download_url'],
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'])
              : null,
      completedAt:
          json['completed_at'] != null
              ? DateTime.parse(json['completed_at'])
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'export_id': exportId,
      'user_id': userId,
      'recording_id': recordingId,
      'export_type': exportType,
      'status': status,
      'file_path': filePath,
      'download_url': downloadUrl,
      'created_at': createdAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
    };
  }
}
