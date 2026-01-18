import 'package:equatable/equatable.dart';

class Task extends Equatable {
  final String id;
  final String taskType;
  final String status;
  final String? result;
  final String? errorMessage;
  final int? audioId;
  final Map<String, dynamic>? metadataJson;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Task({
    required this.id,
    required this.taskType,
    required this.status,
    this.result,
    this.errorMessage,
    this.audioId,
    this.metadataJson,
    required this.createdAt,
    required this.updatedAt,
  });

  String get filename => metadataJson?['filename']?.toString() ?? 'Unknown file';

  bool get isActive =>
      status == 'pending' || status == 'queued' || status == 'processing';

  bool get isTranscribing =>
      taskType.toLowerCase() == 'transcribe' && isActive;

  bool get isSummarizing =>
      taskType.toLowerCase() == 'summarize' && isActive;

  bool get isCompleted => status == 'completed';

  bool get isFailed => status == 'failed';

  @override
  List<Object?> get props => [
    id,
    taskType,
    status,
    result,
    errorMessage,
    audioId,
    metadataJson,
    createdAt,
    updatedAt,
  ];
}
