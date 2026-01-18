import 'package:equatable/equatable.dart';

enum ServerTaskType { uploading, transcribing, summarizing }

class ServerTask extends Equatable {
  final ServerTaskType type;
  final String taskId;
  final String filename;
  final String status;
  final int? progress;
  final DateTime? startedAt;
  final int? audioId;
  final int? transcriptionId;

  const ServerTask({
    required this.type,
    required this.taskId,
    required this.filename,
    required this.status,
    this.progress,
    this.startedAt,
    this.audioId,
    this.transcriptionId,
  });

  @override
  List<Object?> get props => [
    type,
    taskId,
    filename,
    status,
    progress,
    startedAt,
    audioId,
    transcriptionId,
  ];
}
