import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/recording_repository.dart';
import '../../../transcription/domain/repositories/transcription_repository.dart';

class UploadAndTranscribeRecording {
  final RecordingRepository recordingRepository;
  final TranscriptionRepository transcriptionRepository;

  UploadAndTranscribeRecording({
    required this.recordingRepository,
    required this.transcriptionRepository,
  });

  /// Complete flow: Create recording, upload to Supabase, complete upload, and transcribe
  /// Returns recordingId and transcriptId
  Future<Either<Failure, UploadTranscribeResult>> call({
    required File audioFile,
    required String title,
    required String userId,
    String? folderId,
  }) async {
    try {
      // 1. Create recording metadata
      final createResult = await recordingRepository.createRecording(
        folderId: folderId,
        title: title,
        sourceType: 'RECORDED',
      );

      return await createResult.fold(
        (failure) => Left(failure),
        (recording) async {
          // 2. Get file info
          final fileSizeBytes = await audioFile.length();
          final fileSizeMb = fileSizeBytes / (1024 * 1024);
          final originalFileName = audioFile.path.split('/').last;
          
          // Calculate duration (placeholder - would need audio metadata)
          // For now, we'll use 0 and let backend calculate
          const durationSeconds = 0.0;

          // 3. Upload to Supabase and complete upload
          final uploadResult = await recordingRepository.uploadAndCompleteRecording(
            audioFile: audioFile,
            recordingId: recording.recordingId,
            userId: userId,
            fileSizeMb: fileSizeMb,
            durationSeconds: durationSeconds,
            originalFileName: originalFileName,
          );

          return await uploadResult.fold(
            (failure) => Left(failure),
            (updatedRecording) async {
              // 4. Transcribe recording
              final transcribeResult = await transcriptionRepository.transcribeRecording(
                recording.recordingId,
              );

              return transcribeResult.fold(
                (failure) => Left(failure),
                (transcriptionResponse) async {
                  // 5. Get latest transcript
                  final transcriptsResult = await transcriptionRepository.getTranscripts(
                    recordingId: recording.recordingId,
                    latest: true,
                  );

                  return transcriptsResult.fold(
                    (failure) => Left(failure),
                    (transcripts) {
                      if (transcripts.isEmpty) {
                        return Left(ServerFailure('No transcript found after transcription'));
                      }

                      final transcriptId = transcripts.first.transcriptId;
                      
                      return Right(UploadTranscribeResult(
                        recordingId: recording.recordingId,
                        transcriptId: transcriptId,
                        recording: updatedRecording,
                      ));
                    },
                  );
                },
              );
            },
          );
        },
      );
    } catch (e) {
      return Left(ServerFailure('Failed to upload and transcribe: $e'));
    }
  }
}

class UploadTranscribeResult {
  final String recordingId;
  final String transcriptId;
  final dynamic recording; // Recording entity

  UploadTranscribeResult({
    required this.recordingId,
    required this.transcriptId,
    required this.recording,
  });
}

