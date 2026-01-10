import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/repositories/transcription_repository.dart';
import '../../domain/entities/transcription_request.dart';
import '../../domain/entities/transcription_response.dart';
import '../../domain/entities/audio_upload_response.dart';
import '../../domain/entities/transcript.dart';
import '../../domain/entities/transcript_segment.dart';
import '../../domain/entities/recording_speaker.dart';
import '../../domain/usecases/get_transcript_detail.dart';
import '../datasources/transcription_remote_data_source.dart';
import '../models/transcription_models.dart';
import '../../../auth/data/datasources/auth_local_data_source.dart';

class TranscriptionRepositoryImpl implements TranscriptionRepository {
  final TranscriptionRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;
  final AuthLocalDataSource authLocalDataSource;

  TranscriptionRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
    required this.authLocalDataSource,
  });

  @override
  Future<Either<Failure, AudioUploadResponse>> uploadAudio(
    File audioFile,
  ) async {
    // Check if user is authenticated
    final token = await authLocalDataSource.getAccessToken();
    if (token == null) {
      return const Left(
        UnauthorizedFailure('Please login to upload audio files'),
      );
    }

    if (await networkInfo.isConnected) {
      try {
        final responseModel = await remoteDataSource.uploadAudio(audioFile);
        // Convert model to entity
        return Right(responseModel);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, TranscriptionResponse>> transcribeAudio(
    TranscriptionRequest request,
  ) async {
    // Check if user is authenticated
    final token = await authLocalDataSource.getAccessToken();
    if (token == null) {
      return const Left(
        UnauthorizedFailure('Please login to transcribe audio'),
      );
    }

    if (await networkInfo.isConnected) {
      try {
        // Convert entity to model for data source
        final requestModel = TranscriptionRequestModel.fromEntity(request);
        final responseModel = await remoteDataSource.transcribeAudio(
          requestModel,
        );
        // Convert model to entity
        return Right(responseModel);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  // Recording-based transcription (new API)
  @override
  Future<Either<Failure, TranscriptionResponse>> transcribeRecording(
    String recordingId,
  ) async {
    final token = await authLocalDataSource.getAccessToken();
    if (token == null) {
      return const Left(
        UnauthorizedFailure('Please login to transcribe recording'),
      );
    }

    if (await networkInfo.isConnected) {
      try {
        final responseModel = await remoteDataSource.transcribeRecording(
          recordingId,
        );
        return Right(responseModel);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, List<Transcript>>> getTranscripts({
    required String recordingId,
    bool? latest,
  }) async {
    final token = await authLocalDataSource.getAccessToken();
    if (token == null) {
      return const Left(UnauthorizedFailure('Please login to get transcripts'));
    }

    if (await networkInfo.isConnected) {
      try {
        final transcriptModels = await remoteDataSource.getTranscripts(
          recordingId: recordingId,
          latest: latest,
        );
        return Right(transcriptModels);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, TranscriptDetail>> getTranscriptDetail(
    String transcriptId,
  ) async {
    final token = await authLocalDataSource.getAccessToken();
    if (token == null) {
      return const Left(
        UnauthorizedFailure('Please login to get transcript detail'),
      );
    }

    if (await networkInfo.isConnected) {
      try {
        final response = await remoteDataSource.getTranscriptDetail(
          transcriptId,
        );
        // TranscriptDetail response has transcript fields at top level + segments array
        // Extract transcript fields (excluding segments)
        final transcriptJson = Map<String, dynamic>.from(response);
        transcriptJson.remove('segments');
        final transcript = TranscriptModel.fromJson(transcriptJson);
        
        // Extract segments array
        final segments = (response['segments'] as List? ?? [])
            .map(
              (json) => TranscriptSegmentModel.fromJson(
                json as Map<String, dynamic>,
              ),
            )
            .toList();
        return Right(
          TranscriptDetail(transcript: transcript, segments: segments),
        );
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, Transcript>> updateTranscript({
    required String transcriptId,
    String? language,
    bool? isActive,
  }) async {
    final token = await authLocalDataSource.getAccessToken();
    if (token == null) {
      return const Left(
        UnauthorizedFailure('Please login to update transcript'),
      );
    }

    if (await networkInfo.isConnected) {
      try {
        final transcriptModel = await remoteDataSource.updateTranscript(
          transcriptId: transcriptId,
          language: language,
          isActive: isActive,
        );
        return Right(transcriptModel);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, TranscriptSegment>> updateSegment({
    required String transcriptId,
    required int segmentId,
    String? content,
    String? speakerLabel,
  }) async {
    final token = await authLocalDataSource.getAccessToken();
    if (token == null) {
      return const Left(UnauthorizedFailure('Please login to update segment'));
    }

    if (await networkInfo.isConnected) {
      try {
        final segmentModel = await remoteDataSource.updateSegment(
          transcriptId: transcriptId,
          segmentId: segmentId,
          content: content,
          speakerLabel: speakerLabel,
        );
        return Right(segmentModel);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  // Speakers management
  @override
  Future<Either<Failure, List<RecordingSpeaker>>> getSpeakers(
    String recordingId,
  ) async {
    final token = await authLocalDataSource.getAccessToken();
    if (token == null) {
      return const Left(UnauthorizedFailure('Please login to get speakers'));
    }

    if (await networkInfo.isConnected) {
      try {
        final speakerModels = await remoteDataSource.getSpeakers(recordingId);
        return Right(speakerModels);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, RecordingSpeaker>> updateSpeaker({
    required String recordingId,
    required String speakerLabel,
    String? displayName,
    String? color,
  }) async {
    final token = await authLocalDataSource.getAccessToken();
    if (token == null) {
      return const Left(UnauthorizedFailure('Please login to update speaker'));
    }

    if (await networkInfo.isConnected) {
      try {
        final speakerModel = await remoteDataSource.updateSpeaker(
          recordingId: recordingId,
          speakerLabel: speakerLabel,
          displayName: displayName,
          color: color,
        );
        return Right(speakerModel);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  // Folder management
}
