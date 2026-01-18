import 'package:equatable/equatable.dart';

enum PendingTaskType { untranscribedAudio, unsummarizedTranscript }

class PendingTask extends Equatable {
  final PendingTaskType type;
  final int id;
  final String title;
  final String description;
  final DateTime? date;
  final int? fileSize;
  final int? wordCount;

  const PendingTask({
    required this.type,
    required this.id,
    required this.title,
    required this.description,
    this.date,
    this.fileSize,
    this.wordCount,
  });

  @override
  List<Object?> get props => [
    type,
    id,
    title,
    description,
    date,
    fileSize,
    wordCount,
  ];
}
