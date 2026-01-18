import 'package:equatable/equatable.dart';

class AudioUploadResult extends Equatable {
  final int audioId;
  final String filename;
  final String filePath;
  final String taskId;

  const AudioUploadResult({
    required this.audioId,
    required this.filename,
    required this.filePath,
    required this.taskId,
  });

  @override
  List<Object?> get props => [audioId, filename, filePath, taskId];
}
