import 'dart:io';
import 'package:equatable/equatable.dart';

abstract class TranscriptionEvent extends Equatable {
  const TranscriptionEvent();

  @override
  List<Object?> get props => [];
}

class UploadAudioFileEvent extends TranscriptionEvent {
  final File audioFile;

  const UploadAudioFileEvent(this.audioFile);

  @override
  List<Object> get props => [audioFile];
}

class TranscribeAudioEvent extends TranscriptionEvent {
  final int audioId;
  final String languageCode;

  const TranscribeAudioEvent({
    required this.audioId,
    required this.languageCode,
  });

  @override
  List<Object> get props => [audioId, languageCode];
}

class ResetTranscriptionEvent extends TranscriptionEvent {}