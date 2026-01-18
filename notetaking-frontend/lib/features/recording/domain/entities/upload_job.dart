import 'package:equatable/equatable.dart';

class UploadJob extends Equatable {
  final String jobId;
  final String taskType;
  final String status;

  const UploadJob({
    required this.jobId,
    required this.taskType,
    required this.status,
  });

  @override
  List<Object?> get props => [jobId, taskType, status];
}
