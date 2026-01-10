import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/upload_audio.dart';
import '../../domain/usecases/transcribe_audio.dart';
import '../../domain/usecases/get_transcript_detail.dart';
import '../../domain/entities/transcription_request.dart';
import '../../domain/entities/transcript.dart';
import '../../domain/repositories/transcription_repository.dart';
import 'transcription_event.dart';
import 'transcription_state.dart';

class TranscriptionBloc extends Bloc<TranscriptionEvent, TranscriptionState> {
  final UploadAudio uploadAudio;
  final TranscribeAudio transcribeAudio;
  final GetTranscriptDetail getTranscriptDetail;
  final TranscriptionRepository transcriptionRepository;

  TranscriptionBloc({
    required this.uploadAudio,
    required this.transcribeAudio,
    required this.getTranscriptDetail,
    required this.transcriptionRepository,
  }) : super(TranscriptionInitial()) {
    on<UploadAudioFileEvent>(_onUploadAudioFile);
    on<TranscribeAudioEvent>(_onTranscribeAudio);
    on<ResetTranscriptionEvent>(_onReset);
    on<LoadTranscriptDetailEvent>(_onLoadTranscriptDetail);
    on<LoadTranscriptByRecordingIdEvent>(_onLoadTranscriptByRecordingId);
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

  void _onLoadTranscriptDetail(
    LoadTranscriptDetailEvent event,
    Emitter<TranscriptionState> emit,
  ) async {
    emit(TranscriptionLoading());

    final transcriptResult = await getTranscriptDetail(event.transcriptId);

    final transcriptDetail = await transcriptResult.fold((failure) async {
      emit(TranscriptionError(failure.message));
      return null;
    }, (detail) async => detail);

    if (transcriptDetail == null || !emit.isDone) return;

    // Get speakers for the recording
    final speakersResult = await transcriptionRepository.getSpeakers(
      transcriptDetail.transcript.recordingId,
    );

    speakersResult.fold(
      (failure) {
        if (!emit.isDone) {
          emit(TranscriptionError(failure.message));
        }
      },
      (speakers) {
        if (!emit.isDone) {
          emit(
            TranscriptDetailLoaded(
              transcriptDetail: transcriptDetail,
              speakers: speakers,
            ),
          );
        }
      },
    );
  }

  void _onLoadTranscriptByRecordingId(
    LoadTranscriptByRecordingIdEvent event,
    Emitter<TranscriptionState> emit,
  ) async {
    emit(TranscriptionLoading());

    // Step 1: Get latest transcripts for the recording
    final transcriptsResult = await transcriptionRepository.getTranscripts(
      recordingId: event.recordingId,
      latest: true,
    );

    final transcripts = await transcriptsResult.fold((failure) async {
      if (!emit.isDone) {
        emit(TranscriptionError(failure.message));
      }
      return <Transcript>[];
    }, (transcriptsList) async => transcriptsList);

    if (emit.isDone) return;

    // Step 2: Check if transcripts exist
    if (transcripts.isEmpty) {
      emit(const TranscriptionError('No transcript found for this recording'));
      return;
    }

    // Step 3: Get the first (latest) transcript ID
    final latestTranscript = transcripts.first;
    final transcriptId = latestTranscript.transcriptId;

    // Step 4: Get transcript detail with segments
    final transcriptDetailResult = await getTranscriptDetail(transcriptId);

    final transcriptDetail = await transcriptDetailResult.fold((failure) async {
      if (!emit.isDone) {
        emit(TranscriptionError(failure.message));
      }
      return null;
    }, (detail) async => detail);

    if (transcriptDetail == null || emit.isDone) return;

    // Step 5: Get speakers for the recording
    final speakersResult = await transcriptionRepository.getSpeakers(
      event.recordingId,
    );

    speakersResult.fold(
      (failure) {
        if (!emit.isDone) {
          emit(TranscriptionError(failure.message));
        }
      },
      (speakers) {
        if (!emit.isDone) {
          emit(
            TranscriptDetailLoaded(
              transcriptDetail: transcriptDetail,
              speakers: speakers,
            ),
          );
        }
      },
    );
  }
}
