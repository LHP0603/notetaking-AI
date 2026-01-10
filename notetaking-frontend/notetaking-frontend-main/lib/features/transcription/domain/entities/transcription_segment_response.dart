import 'package:equatable/equatable.dart';
import 'transcription_word.dart';

class TranscriptionSegmentResponse extends Equatable {
  final String transcript;
  final double confidence;
  final List<TranscriptionWord> words;

  const TranscriptionSegmentResponse({
    required this.transcript,
    required this.confidence,
    required this.words,
  });

  @override
  List<Object?> get props => [transcript, confidence, words];
}
