import 'package:equatable/equatable.dart';
import 'transcription_segment_response.dart';

class TranscriptionResponse extends Equatable {
  final int audioId;
  final String transcript;
  final double confidence;
  final String languageCode;
  final List<TranscriptionSegmentResponse> segments;
  final int wordCount;
  final double? durationTranscribed;
  final String status;
  final DateTime processedAt;

  const TranscriptionResponse({
    required this.audioId,
    required this.transcript,
    required this.confidence,
    required this.languageCode,
    required this.segments,
    required this.wordCount,
    this.durationTranscribed,
    required this.status,
    required this.processedAt,
  });

  @override
  List<Object?> get props => [
    audioId,
    transcript,
    confidence,
    languageCode,
    segments,
    wordCount,
    durationTranscribed,
    status,
    processedAt,
  ];
}
