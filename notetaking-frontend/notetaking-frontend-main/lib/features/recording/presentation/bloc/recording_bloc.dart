import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/import_audio.dart';
import '../../domain/usecases/start_recording.dart';
import '../../domain/usecases/stop_recording.dart';
import '../../domain/repositories/recording_repository.dart';
import 'recording_event.dart';
import 'recording_state.dart';
import '../../domain/entities/recording.dart';

class RecordingBloc extends Bloc<RecordingEvent, RecordingState> {
  final StartRecording startRecording;
  final StopRecording stopRecording;
  final ImportAudio importAudio;
  final RecordingRepository repository;

  StreamSubscription<Duration>? _durationSubscription;

  RecordingBloc({
    required this.startRecording,
    required this.stopRecording,
    required this.importAudio,
    required this.repository,
  }) : super(const RecordingInitial()) {
    on<StartRecordingRequested>(_onStartRecording);
    on<StopRecordingRequested>(_onStopRecording);
    on<RecordingFinished>(_onRecordingFinished);
    on<PauseRecordingRequested>(_onPauseRecording);
    on<ResumeRecordingRequested>(_onResumeRecording);
    on<ImportAudioRequested>(_onImportAudio);
    on<DurationUpdated>(_onDurationUpdated);
    on<UploadAndTranscribeRecordingRequested>(_onUploadAndTranscribeRecording);
    on<ResetRecordingEvent>(_onReset);
  }

  void _onReset(ResetRecordingEvent event, Emitter<RecordingState> emit) {
    _durationSubscription?.cancel();
    emit(const RecordingInitial());
  }

  Future<void> _onStartRecording(
    StartRecordingRequested event,
    Emitter<RecordingState> emit,
  ) async {
    // UI controls the recorder now, just update state
    emit(const RecordingInProgress());
    _durationSubscription?.cancel();
    // We don't listen to repo duration anymore, UI sends DurationUpdated
  }

  Future<void> _onStopRecording(
    StopRecordingRequested event,
    Emitter<RecordingState> emit,
  ) async {
    // UI triggers this now via RecordingFinished, or this event is deprecated for internal logic
    // But keeping it empty or redirecting just in case
  }

  Future<void> _onRecordingFinished(
    RecordingFinished event,
    Emitter<RecordingState> emit,
  ) async {
    _durationSubscription?.cancel();

    final now = DateTime.now();
    final title = 'Recording ${now.toString()}';

    final recording = Recording(
      recordingId: 'temp_id_${now.millisecondsSinceEpoch}',
      userId: 'local_user',
      title: title,
      filePath: event.path,
      durationSeconds: event.duration.inSeconds.toDouble(),
      fileSizeMb: 0,
      status: RecordingStatus.uploading,
      sourceType: SourceType.recorded,
      isPinned: false,
      isTrashed: false,
      createdAt: now,
    );

    emit(RecordingCompleted(recording: recording));
  }

  Future<void> _onPauseRecording(
    PauseRecordingRequested event,
    Emitter<RecordingState> emit,
  ) async {
    _durationSubscription?.cancel();

    final result = await repository.pauseRecording();

    result.fold((failure) => emit(RecordingError(message: failure.message)), (
      _,
    ) {
      if (state is RecordingInProgress) {
        emit(
          RecordingPaused(duration: (state as RecordingInProgress).duration),
        );
      }
    });
  }

  Future<void> _onResumeRecording(
    ResumeRecordingRequested event,
    Emitter<RecordingState> emit,
  ) async {
    final currentDuration =
        state is RecordingPaused
            ? (state as RecordingPaused).duration
            : Duration.zero;

    final result = await repository.resumeRecording();

    result.fold((failure) => emit(RecordingError(message: failure.message)), (
      _,
    ) {
      emit(RecordingInProgress(duration: currentDuration));
      _durationSubscription?.cancel();
      _durationSubscription = repository.durationStream.listen((duration) {
        add(DurationUpdated(duration));
      });
    });
  }

  Future<void> _onImportAudio(
    ImportAudioRequested event,
    Emitter<RecordingState> emit,
  ) async {
    final result = await importAudio();

    result.fold(
      (failure) => emit(RecordingError(message: failure.message)),
      (file) => emit(AudioImported(audioFile: file)),
    );
  }

  void _onDurationUpdated(DurationUpdated event, Emitter<RecordingState> emit) {
    if (state is RecordingInProgress) {
      emit(RecordingInProgress(duration: event.duration));
    }
  }

  Future<void> _onUploadAndTranscribeRecording(
    UploadAndTranscribeRecordingRequested event,
    Emitter<RecordingState> emit,
  ) async {
    try {
      // Step 1: Creating recording metadata
      emit(const CreatingRecording());

      final result = await repository.uploadAndTranscribeRecording(
        audioFile: event.audioFile,
        title: event.title,
        userId: event.userId,
        folderId: event.folderId,
      );

      result.fold(
        (failure) => emit(
          RecordingError(
            message: failure.message,
            step: 'Upload and transcribe',
          ),
        ),
        (uploadResult) {
          // All steps completed successfully
          emit(
            UploadComplete(
              recordingId: uploadResult.recordingId,
              transcriptId: uploadResult.transcriptId,
              recording: uploadResult.recording,
              segments: uploadResult.segments,
            ),
          );
        },
      );
    } catch (e) {
      emit(
        RecordingError(
          message: 'Unexpected error: $e',
          step: 'Upload and transcribe',
        ),
      );
    }
  }

  @override
  Future<void> close() {
    _durationSubscription?.cancel();
    return super.close();
  }
}
