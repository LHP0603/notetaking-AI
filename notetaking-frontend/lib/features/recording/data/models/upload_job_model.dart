import '../../domain/entities/upload_job.dart';

class UploadJobModel extends UploadJob {
  const UploadJobModel({
    required super.jobId,
    required super.taskType,
    required super.status,
  });

  factory UploadJobModel.fromJson(Map<String, dynamic> json) {
    return UploadJobModel(
      jobId: json['job_id'] as String,
      taskType: json['task_type'] as String,
      status: json['status'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'job_id': jobId,
      'task_type': taskType,
      'status': status,
    };
  }
}
