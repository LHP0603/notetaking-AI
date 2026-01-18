import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/recording.dart';
import '../../domain/entities/upload_job.dart';
import '../../domain/repositories/recording_repository.dart';
import '../../../auth/data/datasources/auth_local_data_source.dart';
import '../../../../core/network/network_info.dart';
import '../datasources/recording_remote_data_source.dart';
import '../datasources/recording_local_data_source.dart';

class RecordingRepositoryImpl implements RecordingRepository {
  final RecordingLocalDataSource localDataSource;
  final RecordingRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;
  final AuthLocalDataSource authLocalDataSource;

  RecordingRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    required this.networkInfo,
    required this.authLocalDataSource,
  });

  @override
  Future<Either<Failure, void>> startRecording() async {
    try {
      await localDataSource.startRecording();
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('An unexpected error occurred: $e'));
    }
  }

  @override
  Future<Either<Failure, Recording>> stopRecording() async {
    try {
      final recording = await localDataSource.stopRecording();
      return Right(recording);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('An unexpected error occurred: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> pauseRecording() async {
    try {
      await localDataSource.pauseRecording();
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('An unexpected error occurred: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> resumeRecording() async {
    try {
      await localDataSource.resumeRecording();
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('An unexpected error occurred: $e'));
    }
  }

  @override
  Future<Either<Failure, File>> importAudioFile() async {
    try {
      final file = await localDataSource.importAudioFile();
      return Right(file);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('An unexpected error occurred: $e'));
    }
  }

  @override
  Future<Either<Failure, UploadJob>> uploadRecordingAsync(
    File audioFile,
  ) async {
    final token = await authLocalDataSource.getAccessToken();
    if (token == null) {
      return const Left(UnauthorizedFailure('Please login to upload audio'));
    }

    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }

    try {
      final job = await remoteDataSource.uploadRecordingAsync(audioFile);
      return Right(job);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return const Left(
        ServerFailure('Unexpected error occurred during upload'),
      );
    }
  }

  @override
  RecordingStatus getRecordingStatus() {
    return localDataSource.getRecordingStatus();
  }

  @override
  Stream<Duration> get durationStream => localDataSource.durationStream;
}




