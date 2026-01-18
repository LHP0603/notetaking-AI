import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/upload_audio.dart';
import '../../domain/usecases/transcribe_audio.dart';
import '../../data/models/transcription_models.dart';
import 'transcription_event.dart';
import 'transcription_state.dart';

class TranscriptionBloc extends Bloc<TranscriptionEvent, TranscriptionState> {
  final UploadAudio uploadAudio;
  final TranscribeAudio transcribeAudio;

  TranscriptionBloc({
    required this.uploadAudio,
    required this.transcribeAudio,
  }) : super(TranscriptionInitial()) {
    on<UploadAudioFileEvent>(_onUploadAudioFile);
    on<TranscribeAudioEvent>(_onTranscribeAudio);
    on<ResetTranscriptionEvent>(_onReset);
  }

  void _onUploadAudioFile(
    UploadAudioFileEvent event,
    Emitter<TranscriptionState> emit,
  ) async {
    emit(TranscriptionLoading());

    final result = await uploadAudio(event.audioFile);

    result.fold(
      (failure) => emit(TranscriptionError(failure.message)),
      (success) => emit(AudioUploadSuccess(success)),
    );
  }

  void _onTranscribeAudio(
    TranscribeAudioEvent event,
    Emitter<TranscriptionState> emit,
  ) async {
    emit(TranscriptionLoading());

    final request = TranscriptionRequest(
      audioId: event.audioId,
      languageCode: event.languageCode,
    );

    final result = await transcribeAudio(request);

    result.fold(
      (failure) => emit(TranscriptionError(failure.message)),
      (success) => emit(TranscriptionSuccess(success)),
    );
  }

  void _onReset(
    ResetTranscriptionEvent event,
    Emitter<TranscriptionState> emit,
  ) {
    emit(TranscriptionInitial());
  }
}