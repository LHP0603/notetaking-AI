import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/audio_upload_response.dart';
import '../entities/transcription_request.dart';
import '../entities/transcription_response.dart';
import '../entities/transcript.dart';
import '../entities/transcript_segment.dart';
import '../entities/recording_speaker.dart';
import '../usecases/get_transcript_detail.dart';

abstract class TranscriptionRepository {
  // Audio upload and transcription (legacy - to be updated)
  Future<Either<Failure, AudioUploadResponse>> uploadAudio(File audioFile);
  Future<Either<Failure, TranscriptionResponse>> transcribeAudio(TranscriptionRequest request);

  // Recording-based transcription (new API)
  /// Transcribe a recording - POST /recordings/:id/transcribe
  Future<Either<Failure, TranscriptionResponse>> transcribeRecording(String recordingId);
  
  /// Get transcripts for a recording - GET /recordings/:id/transcripts
  Future<Either<Failure, List<Transcript>>> getTranscripts({
    required String recordingId,
    bool? latest,
  });
  
  /// Get transcript detail with segments - GET /transcripts/:id
  Future<Either<Failure, TranscriptDetail>> getTranscriptDetail(String transcriptId);
  
  /// Update transcript metadata - PATCH /transcripts/:id
  Future<Either<Failure, Transcript>> updateTranscript({
    required String transcriptId,
    String? language,
    bool? isActive,
  });
  
  /// Update transcript segment - PATCH /transcripts/:transcript_id/segments/:segment_id
  Future<Either<Failure, TranscriptSegment>> updateSegment({
    required String transcriptId,
    required int segmentId,
    String? content,
    String? speakerLabel,
  });

  // Speakers management
  /// Get speakers for a recording - GET /recordings/:id/speakers
  Future<Either<Failure, List<RecordingSpeaker>>> getSpeakers(String recordingId);
  
  /// Update speaker display name - PATCH /recordings/:id/speakers/:speaker_label
  Future<Either<Failure, RecordingSpeaker>> updateSpeaker({
    required String recordingId,
    required String speakerLabel,
    String? displayName,
    String? color,
  });
}