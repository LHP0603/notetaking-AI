import 'package:equatable/equatable.dart';

class Transcript extends Equatable {
  final String transcriptId; // uuid transcript_id PK
  final String recordingId; // uuid recording_id FK
  final String language; // VD: en, vi
  final double confidenceScore; // Độ tin cậy AI
  final DateTime createdAt;
  final int? versionNo; // Optional: version number
  final String? type; // Optional: transcript type (e.g., AI_GENERATED)
  final bool? isActive; // Optional: whether transcript is active

  const Transcript({
    required this.transcriptId,
    required this.recordingId,
    required this.language,
    required this.confidenceScore,
    required this.createdAt,
    this.versionNo,
    this.type,
    this.isActive,
  });

  @override
  List<Object?> get props => [
    transcriptId,
    recordingId,
    language,
    confidenceScore,
    createdAt,
    versionNo,
    type,
    isActive,
  ];
}

