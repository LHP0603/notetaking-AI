import 'package:equatable/equatable.dart';

class RecordingTag extends Equatable {
  final int id; // PK
  final String recordingId; // FK to RECORDINGS
  final String tag; // Normalized tag text (lowercase, trimmed)

  const RecordingTag({
    required this.id,
    required this.recordingId,
    required this.tag,
  });

  @override
  List<Object?> get props => [id, recordingId, tag];
}

