import '../../domain/entities/export_job.dart';

class ExportJobModel extends ExportJob {
  const ExportJobModel({
    required int jobId,
    required String userId,
    required String recordingId,
    required ExportType exportType,
    required ExportJobStatus status,
    String? filePath,
    String? errorMessage,
    required DateTime createdAt,
    DateTime? completedAt,
  }) : super(
         jobId: jobId,
         userId: userId,
         recordingId: recordingId,
         exportType: exportType,
         status: status,
         filePath: filePath,
         errorMessage: errorMessage,
         createdAt: createdAt,
         completedAt: completedAt,
       );

  factory ExportJobModel.fromJson(Map<String, dynamic> json) {
    return ExportJobModel(
      jobId: json['job_id'] as int,
      userId: json['user_id'] as String,
      recordingId: json['recording_id'] as String,
      exportType: ExportType.fromString(json['export_type'] as String),
      status: ExportJobStatus.fromString(json['status'] as String),
      filePath: json['file_path'] as String?,
      errorMessage: json['error_message'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'job_id': jobId,
      'user_id': userId,
      'recording_id': recordingId,
      'export_type': exportType.value,
      'status': status.value,
      'file_path': filePath,
      'error_message': errorMessage,
      'created_at': createdAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  factory ExportJobModel.fromEntity(ExportJob entity) {
    return ExportJobModel(
      jobId: entity.jobId,
      userId: entity.userId,
      recordingId: entity.recordingId,
      exportType: entity.exportType,
      status: entity.status,
      filePath: entity.filePath,
      errorMessage: entity.errorMessage,
      createdAt: entity.createdAt,
      completedAt: entity.completedAt,
    );
  }
}

