import 'dart:io';
import 'package:equatable/equatable.dart';
import '../../domain/entities/recording.dart';
import '../../domain/entities/upload_job.dart';

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

class RecordingCompletedMaxDuration extends RecordingState {
  final Recording recording;
  final String message;

  const RecordingCompletedMaxDuration({
    required this.recording,
    required this.message,
  });

  @override
  List<Object?> get props => [recording, message];
}

class RecordingUploading extends RecordingState {
  const RecordingUploading();
}

class RecordingUploadSuccess extends RecordingState {
  final UploadJob uploadJob;
  final String message;

  const RecordingUploadSuccess({
    required this.uploadJob,
    required this.message,
  });

  @override
  List<Object?> get props => [uploadJob, message];
}

class AudioImported extends RecordingState {
  final File audioFile;

  const AudioImported({required this.audioFile});

  @override
  List<Object?> get props => [audioFile];
}

class RecordingError extends RecordingState {
  final String message;

  const RecordingError({required this.message});

  @override
  List<Object?> get props => [message];
}




