import 'package:equatable/equatable.dart';

enum RecordingStatus { idle, recording, paused, completed }

class Recording extends Equatable {
  final String? id;
  final String? filePath;
  final String? fileName;
  final Duration duration;
  final DateTime? createdAt;
  final RecordingStatus status;

  const Recording({
    this.id,
    this.filePath,
    this.fileName,
    this.duration = Duration.zero,
    this.createdAt,
    this.status = RecordingStatus.idle,
  });

  Recording copyWith({
    String? id,
    String? filePath,
    String? fileName,
    Duration? duration,
    DateTime? createdAt,
    RecordingStatus? status,
  }) {
    return Recording(
      id: id ?? this.id,
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
      duration: duration ?? this.duration,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [id, filePath, fileName, duration, createdAt, status];
}





