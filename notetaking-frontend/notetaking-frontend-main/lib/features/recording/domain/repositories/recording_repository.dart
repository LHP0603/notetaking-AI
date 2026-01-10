import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/recording.dart';
import '../entities/marker.dart';
import '../entities/recording_tag.dart';
import '../entities/export_job.dart';
import '../../../transcription/domain/entities/transcript_segment.dart';

class UploadTranscribeResult {
  final String recordingId;
  final String transcriptId;
  final Recording recording;
  final List<TranscriptSegment> segments;

  UploadTranscribeResult({
    required this.recordingId,
    required this.transcriptId,
    required this.recording,
    required this.segments,
  });
}

abstract class RecordingRepository {
  // Local recording methods (for UI/recording session management)
  /// Start recording audio
  Future<Either<Failure, void>> startRecording();

  /// Stop recording and return the recording entity
  Future<Either<Failure, Recording>> stopRecording();

  /// Pause the current recording
  Future<Either<Failure, void>> pauseRecording();

  /// Resume the paused recording
  Future<Either<Failure, void>> resumeRecording();

  /// Import an audio file from device storage
  Future<Either<Failure, File>> importAudioFile();

  /// Get the current local recording session status
  LocalRecordingState getRecordingStatus();

  /// Get the current recording duration stream
  Stream<Duration> get durationStream;

  // API-based methods
  /// Create recording metadata - POST /recordings
  Future<Either<Failure, Recording>> createRecording({
    required String? folderId,
    required String title,
    required String sourceType,
  });

  /// Upload audio file to Supabase and complete upload
  Future<Either<Failure, Recording>> uploadAndCompleteRecording({
    required File audioFile,
    required String recordingId,
    required String userId,
    required double fileSizeMb,
    required double durationSeconds,
    required String originalFileName,
  });

  /// Complete flow: Upload audio, complete upload, and transcribe
  /// Returns recordingId and transcriptId
  Future<Either<Failure, UploadTranscribeResult>> uploadAndTranscribeRecording({
    required File audioFile,
    required String title,
    required String userId,
    String? folderId,
  });

  /// Complete upload - POST /recordings/:id/complete-upload
  Future<Either<Failure, Recording>> completeUpload({
    required String recordingId,
    required String filePath,
    required double fileSizeMb,
    required double durationSeconds,
    required String originalFileName,
  });

  /// Get recordings list - GET /recordings
  Future<Either<Failure, List<Recording>>> getRecordings({
    String? folderId,
    bool? isTrashed,
    String? search,
    String? tag,
    int? page,
    int? pageSize,
  });

  /// Get recording detail - GET /recordings/:id
  Future<Either<Failure, Recording>> getRecordingDetail(String recordingId);

  /// Update recording - PATCH /recordings/:id
  Future<Either<Failure, Recording>> updateRecording({
    required String recordingId,
    String? title,
    String? folderId,
    bool? isPinned,
    double? lastPlayPosition,
  });

  /// Soft delete recording - DELETE /recordings/:id
  Future<Either<Failure, void>> softDeleteRecording(String recordingId);
  Future<ExportJob> exportRecording(
    String recordingId,
    String exportType,
  ); // Updated return type
  Future<ExportJob> getExportJob(String exportId); // Added new method

  /// Restore recording - POST /recordings/:id/restore
  Future<Either<Failure, Recording>> restoreRecording(String recordingId);

  /// Hard delete recording - DELETE /recordings/:id/hard-delete
  Future<Either<Failure, void>> hardDeleteRecording(String recordingId);

  // Markers management
  Future<Either<Failure, Marker>> createMarker({
    required String recordingId,
    required double timeSeconds,
    required String label,
    required String type,
    String? description,
  });
  Future<Either<Failure, List<Marker>>> getMarkers(String recordingId);
  Future<Either<Failure, Marker>> updateMarker({
    required int markerId,
    String? label,
    String? type,
    String? description,
  });
  Future<Either<Failure, void>> deleteMarker(int markerId);

  // Tags management
  Future<Either<Failure, List<RecordingTag>>> addTags({
    required String recordingId,
    required List<String> tags,
  });
  Future<Either<Failure, void>> removeTag({
    required String recordingId,
    required String tag,
  });
  Future<Either<Failure, List<RecordingTag>>> getTags(String recordingId);
}
