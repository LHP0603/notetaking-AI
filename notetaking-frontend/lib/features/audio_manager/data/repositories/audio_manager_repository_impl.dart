import 'dart:io';
import 'package:dartz/dartz.dart' hide Task;
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../auth/data/datasources/auth_local_data_source.dart';
import '../../domain/entities/audio_file_page.dart';
import '../../domain/entities/audio_filter.dart';
import '../../domain/entities/audio_upload_result.dart';
import '../../domain/entities/audio_file.dart';
import '../../domain/entities/note.dart';
import '../../domain/entities/pending_task_bucket.dart';
import '../../domain/entities/server_task_bucket.dart';
import '../../domain/entities/task.dart';
import '../../domain/entities/task_search_criteria.dart';
import '../../domain/repositories/audio_manager_repository.dart';
import '../datasources/audio_manager_local_data_source.dart';
import '../datasources/audio_manager_remote_data_source.dart';
import '../models/audio_filter_model.dart';

class AudioManagerRepositoryImpl implements AudioManagerRepository {
  final AudioManagerRemoteDataSource remoteDataSource;
  final AudioManagerLocalDataSource localDataSource;
  final NetworkInfo networkInfo;
  final AuthLocalDataSource authLocalDataSource;

  AudioManagerRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
    required this.authLocalDataSource,
  });

  @override
  Future<Either<Failure, AudioFilePage>> getUploadedAudios(
    AudioFilter filter,
  ) async {
    final token = await authLocalDataSource.getAccessToken();
    if (token == null) {
      return const Left(UnauthorizedFailure('Please login to view audio files'));
    }

    if (await networkInfo.isConnected) {
      try {
        final page = await remoteDataSource.getAudioFiles(
          AudioFilterModel(
            search: filter.search,
            fromDate: filter.fromDate,
            toDate: filter.toDate,
            hasTranscript: filter.hasTranscript,
            hasSummary: filter.hasSummary,
            order: filter.order,
            page: filter.page,
            limit: filter.limit,
            status: filter.status,
          ),
        );
        await localDataSource.cacheAudioFiles(page);
        return Right(page);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } on NetworkException catch (e) {
        return Left(NetworkFailure(e.message));
      }
    }

    final cached = await localDataSource.getCachedAudioFiles();
    if (cached != null) {
      return Right(cached);
    }

    return const Left(NetworkFailure('No internet connection'));
  }

  @override
  Future<Either<Failure, AudioFile>> getAudioFileById(int audioId) async {
    final token = await authLocalDataSource.getAccessToken();
    if (token == null) {
      return const Left(
        UnauthorizedFailure('Please login to view audio details'),
      );
    }

    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }

    try {
      final audioFile = await remoteDataSource.getAudioFileById(audioId);
      return Right(audioFile);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, AudioUploadResult>> uploadAudioFile(
    File audioFile,
  ) async {
    final token = await authLocalDataSource.getAccessToken();
    if (token == null) {
      return const Left(UnauthorizedFailure('Please login to upload audio'));
    }

    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.uploadAudioFile(audioFile);
        return Right(result);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } on NetworkException catch (e) {
        return Left(NetworkFailure(e.message));
      }
    }

    return const Left(NetworkFailure('No internet connection'));
  }

  @override
  Future<Either<Failure, AudioFile>> renameAudio(
    int audioId,
    String newName,
  ) async {
    final token = await authLocalDataSource.getAccessToken();
    if (token == null) {
      return const Left(
        UnauthorizedFailure('Please login to rename audio'),
      );
    }

    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }

    try {
      final updatedAudio = await remoteDataSource.renameAudio(audioId, newName);
      return Right(updatedAudio);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, bool>> deleteAudio(int audioId) async {
    final token = await authLocalDataSource.getAccessToken();
    if (token == null) {
      return const Left(
        UnauthorizedFailure('Please login to delete audio'),
      );
    }

    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }

    try {
      await remoteDataSource.deleteAudio(audioId);
      return const Right(true);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, String>> downloadAudio(
    int audioId,
    String filename,
  ) async {
    final token = await authLocalDataSource.getAccessToken();
    if (token == null) {
      return const Left(
        UnauthorizedFailure('Please login to download audio'),
      );
    }

    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }

    try {
      final filePath =
          await remoteDataSource.downloadAudio(audioId, filename);
      return Right(filePath);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<Task>>> getActiveTasks(int audioId) async {
    final token = await authLocalDataSource.getAccessToken();
    if (token == null) {
      return const Left(UnauthorizedFailure('Please login to view tasks'));
    }

    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }

    try {
      final tasks = await remoteDataSource.getActiveTasks(audioId);
      return Right(tasks);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, AudioFile>> updateTranscription(
    int audioId,
    String transcription,
  ) async {
    final token = await authLocalDataSource.getAccessToken();
    if (token == null) {
      return const Left(
        UnauthorizedFailure('Please login to update transcription'),
      );
    }

    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }

    try {
      final updatedAudio = await remoteDataSource.updateTranscription(
        audioId,
        transcription,
      );
      return Right(updatedAudio);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, bool>> startTranscription(int audioId) async {
    final token = await authLocalDataSource.getAccessToken();
    if (token == null) {
      return const Left(
        UnauthorizedFailure('Please login to start transcription'),
      );
    }

    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }

    try {
      await remoteDataSource.startTranscription(audioId);
      return const Right(true);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, Note?>> getSummaryNote(int audioFileId) async {
    final token = await authLocalDataSource.getAccessToken();
    if (token == null) {
      return const Left(UnauthorizedFailure('Please login to view summary'));
    }

    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }

    try {
      final note = await remoteDataSource.getSummaryNote(audioFileId);
      return Right(note);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, Note>> getNoteById(int noteId) async {
    final token = await authLocalDataSource.getAccessToken();
    if (token == null) {
      return const Left(UnauthorizedFailure('Please login to view note'));
    }

    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }

    try {
      final note = await remoteDataSource.getNoteById(noteId);
      return Right(note);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, bool>> startSummarization(int audioFileId) async {
    final token = await authLocalDataSource.getAccessToken();
    if (token == null) {
      return const Left(
        UnauthorizedFailure('Please login to start summarization'),
      );
    }

    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }

    try {
      await remoteDataSource.startSummarization(audioFileId);
      return const Right(true);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, Note>> updateNoteSummary(
    int noteId,
    String summary,
  ) async {
    final token = await authLocalDataSource.getAccessToken();
    if (token == null) {
      return const Left(UnauthorizedFailure('Please login to update summary'));
    }

    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }

    try {
      final note = await remoteDataSource.updateNoteSummary(noteId, summary);
      return Right(note);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, ServerTaskBucket>> getServerTasks() async {
    final token = await authLocalDataSource.getAccessToken();
    if (token == null) {
      return const Left(UnauthorizedFailure('Please login to view tasks'));
    }

    if (await networkInfo.isConnected) {
      try {
        final tasks = await remoteDataSource.getServerTasks();
        await localDataSource.cacheServerTasks(tasks);
        return Right(tasks);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } on NetworkException catch (e) {
        return Left(NetworkFailure(e.message));
      }
    }

    final cached = await localDataSource.getCachedServerTasks();
    if (cached != null) {
      return Right(cached);
    }

    return const Left(NetworkFailure('No internet connection'));
  }

  @override
  Future<Either<Failure, PendingTaskBucket>> getPendingTasks() async {
    final token = await authLocalDataSource.getAccessToken();
    if (token == null) {
      return const Left(UnauthorizedFailure('Please login to view pending tasks'));
    }

    if (await networkInfo.isConnected) {
      try {
        final tasks = await remoteDataSource.getPendingTasks();
        await localDataSource.cachePendingTasks(tasks);
        return Right(tasks);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } on NetworkException catch (e) {
        return Left(NetworkFailure(e.message));
      }
    }

    final cached = await localDataSource.getCachedPendingTasks();
    if (cached != null) {
      return Right(cached);
    }

    return const Left(NetworkFailure('No internet connection'));
  }

  @override
  Future<Either<Failure, List<Task>>> searchTasks(
    TaskSearchCriteria criteria,
  ) async {
    final token = await authLocalDataSource.getAccessToken();
    if (token == null) {
      return const Left(UnauthorizedFailure('Please login to view tasks'));
    }

    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }

    try {
      final tasks = await remoteDataSource.searchTasks(criteria);
      return Right(tasks);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    }
  }
}
