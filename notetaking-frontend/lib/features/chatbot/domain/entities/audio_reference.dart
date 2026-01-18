import 'package:equatable/equatable.dart';

class AudioReference extends Equatable {
  final int audioId;
  final String title;
  final double duration;
  final DateTime createdAt;

  const AudioReference({
    required this.audioId,
    required this.title,
    required this.duration,
    required this.createdAt,
  });

  String get formattedDuration {
    final totalSeconds = duration.toInt();
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    if (hours > 0) {
      return '${hours}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  List<Object?> get props => [audioId, title, duration, createdAt];
}
