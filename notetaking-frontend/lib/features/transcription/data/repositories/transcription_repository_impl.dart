import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/repositories/transcription_repository.dart';
import '../datasources/transcription_remote_data_source.dart';
import '../models/audio_upload_response.dart';
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
  Future<Either<Failure, AudioUploadResponse>> uploadAudio(File audioFile) async {
    // Check if user is authenticated
    final token = await authLocalDataSource.getAccessToken();
    if (token == null) {
      return const Left(UnauthorizedFailure('Please login to upload audio files'));
    }

    if (await networkInfo.isConnected) {
      try {
        final response = await remoteDataSource.uploadAudio(audioFile);
        return Right(response);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, TranscriptionResponse>> transcribeAudio(
      TranscriptionRequest request) async {
    // Check if user is authenticated
    final token = await authLocalDataSource.getAccessToken();
    if (token == null) {
      return const Left(UnauthorizedFailure('Please login to transcribe audio'));
    }

    if (await networkInfo.isConnected) {
      try {
        final response = await remoteDataSource.transcribeAudio(request);
        return Right(response);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }
}