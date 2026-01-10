import 'package:equatable/equatable.dart';

class TranscriptionRequest extends Equatable {
  final int audioId;
  final String languageCode;

  const TranscriptionRequest({
    required this.audioId,
    required this.languageCode,
  });

  @override
  List<Object?> get props => [audioId, languageCode];
}
