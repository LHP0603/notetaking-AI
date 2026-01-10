import 'package:equatable/equatable.dart';

class AudioFile extends Equatable {
  final String filename;
  final String originalFilename;
  final int fileSize;
  final double duration;
  final String format;
  final int id;
  final int userId;
  final String filePath;
  final String status;
  final String? transcription;
  final double? confidenceScore;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AudioFile({
    required this.filename,
    required this.originalFilename,
    required this.fileSize,
    required this.duration,
    required this.format,
    required this.id,
    required this.userId,
    required this.filePath,
    required this.status,
    this.transcription,
    this.confidenceScore,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
    filename,
    originalFilename,
    fileSize,
    duration,
    format,
    id,
    userId,
    filePath,
    status,
    transcription,
    confidenceScore,
    createdAt,
    updatedAt,
  ];
}

