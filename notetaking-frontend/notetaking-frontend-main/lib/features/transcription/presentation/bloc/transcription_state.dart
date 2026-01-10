import 'package:equatable/equatable.dart';
import '../../domain/entities/audio_upload_response.dart';
import '../../domain/entities/transcription_response.dart';
import '../../domain/usecases/get_transcript_detail.dart';
import '../../domain/entities/recording_speaker.dart';

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

class TranscriptDetailLoaded extends TranscriptionState {
  final TranscriptDetail transcriptDetail;
  final List<RecordingSpeaker> speakers;

  const TranscriptDetailLoaded({
    required this.transcriptDetail,
    required this.speakers,
  });

  @override
  List<Object> get props => [transcriptDetail, speakers];
}