import 'dart:io';
import 'package:equatable/equatable.dart';
import '../../domain/entities/recording.dart';
import '../../../transcription/domain/entities/transcript_segment.dart';

abstract class RecordingState extends Equatable {
  const RecordingState();

  @override
  List<Object?> get props => [];
}

class RecordingInitial extends RecordingState {
  const RecordingInitial();
}

class RecordingInProgress extends RecordingState {
  final Duration duration;

  const RecordingInProgress({this.duration = Duration.zero});

  @override
  List<Object?> get props => [duration];
}

class RecordingPaused extends RecordingState {
  final Duration duration;

  const RecordingPaused({required this.duration});

  @override
  List<Object?> get props => [duration];
}

class RecordingCompleted extends RecordingState {
  final Recording recording;

  const RecordingCompleted({required this.recording});

  @override
  List<Object?> get props => [recording];
}

class AudioImported extends RecordingState {
  final File audioFile;

  const AudioImported({required this.audioFile});

  @override
  List<Object?> get props => [audioFile];
}

class RecordingError extends RecordingState {
  final String message;
  final String? step; // Optional step information for better error context

  const RecordingError({
    required this.message,
    this.step,
  });

  @override
  List<Object?> get props => [message, step];
}

class CreatingRecording extends RecordingState {
  const CreatingRecording();
}

class UploadingToSupabase extends RecordingState {
  const UploadingToSupabase();
}

class CompletingUpload extends RecordingState {
  const CompletingUpload();
}

class TranscribingRecording extends RecordingState {
  final String recordingId;

  const TranscribingRecording({required this.recordingId});

  @override
  List<Object?> get props => [recordingId];
}

class FetchingSegments extends RecordingState {
  final String recordingId;
  final String transcriptId;

  const FetchingSegments({
    required this.recordingId,
    required this.transcriptId,
  });

  @override
  List<Object?> get props => [recordingId, transcriptId];
}

class UploadComplete extends RecordingState {
  final String recordingId;
  final String transcriptId;
  final Recording recording;
  final List<TranscriptSegment> segments;

  const UploadComplete({
    required this.recordingId,
    required this.transcriptId,
    required this.recording,
    required this.segments,
  });

  @override
  List<Object?> get props => [recordingId, transcriptId, recording, segments];
}

// Legacy states for backward compatibility
class UploadingRecording extends RecordingState {
  const UploadingRecording();
}

class RecordingTranscribed extends RecordingState {
  final String recordingId;
  final String transcriptId;
  final Recording recording;

  const RecordingTranscribed({
    required this.recordingId,
    required this.transcriptId,
    required this.recording,
  });

  @override
  List<Object?> get props => [recordingId, transcriptId, recording];
}











