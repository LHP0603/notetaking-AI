import 'package:equatable/equatable.dart';
import '../../data/models/audio_upload_response.dart';
import '../../data/models/transcription_models.dart';

abstract class TranscriptionState extends Equatable {
  const TranscriptionState();

  @override
  List<Object?> get props => [];
}

class TranscriptionInitial extends TranscriptionState {}

class TranscriptionLoading extends TranscriptionState {}

class AudioUploadSuccess extends TranscriptionState {
  final AudioUploadResponse uploadResponse;

  const AudioUploadSuccess(this.uploadResponse);

  @override
  List<Object> get props => [uploadResponse];
}

class TranscriptionSuccess extends TranscriptionState {
  final TranscriptionResponse transcriptionResponse;

  const TranscriptionSuccess(this.transcriptionResponse);

  @override
  List<Object> get props => [transcriptionResponse];
}

class TranscriptionError extends TranscriptionState {
  final String message;

  const TranscriptionError(this.message);

  @override
  List<Object> get props => [message];
}