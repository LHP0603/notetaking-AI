import 'dart:io';
import 'package:equatable/equatable.dart';

abstract class RecordingEvent extends Equatable {
  const RecordingEvent();

  @override
  List<Object?> get props => [];
}

class StartRecordingRequested extends RecordingEvent {
  const StartRecordingRequested();
}

class StopRecordingRequested extends RecordingEvent {
  const StopRecordingRequested();
}

class PauseRecordingRequested extends RecordingEvent {
  const PauseRecordingRequested();
}

class ResumeRecordingRequested extends RecordingEvent {
  const ResumeRecordingRequested();
}

class ImportAudioRequested extends RecordingEvent {
  const ImportAudioRequested();
}

class DurationUpdated extends RecordingEvent {
  final Duration duration;

  const DurationUpdated(this.duration);

  @override
  List<Object?> get props => [duration];
}

class AutoStopRecordingTriggered extends RecordingEvent {
  const AutoStopRecordingTriggered();
}

class UploadRecordingRequested extends RecordingEvent {
  final File audioFile;

  const UploadRecordingRequested(this.audioFile);

  @override
  List<Object?> get props => [audioFile];
}




