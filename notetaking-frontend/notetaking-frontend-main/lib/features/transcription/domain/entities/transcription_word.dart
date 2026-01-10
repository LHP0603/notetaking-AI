import 'package:equatable/equatable.dart';

class TranscriptionWord extends Equatable {
  final String word;
  final double startTime;
  final double endTime;
  final double confidence;

  const TranscriptionWord({
    required this.word,
    required this.startTime,
    required this.endTime,
    required this.confidence,
  });

  @override
  List<Object?> get props => [word, startTime, endTime, confidence];
}
