import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/summary.dart';
import '../../domain/repositories/summary_repository.dart';
import '../datasources/summary_remote_data_source.dart';
import '../datasources/summary_local_data_source.dart';
import '../models/summary_model.dart';
import '../../../auth/data/datasources/auth_local_data_source.dart';

class SummaryRepositoryImpl implements SummaryRepository {
  final SummaryRemoteDataSource remoteDataSource;
  final SummaryLocalDataSource localDataSource;
  final NetworkInfo networkInfo;
  final AuthLocalDataSource authLocalDataSource;

  SummaryRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
    required this.authLocalDataSource,
  });

  @override
  Future<Either<Failure, Summary>> getSummary(String transcriptionId) async {
    // Check if user is authenticated
    final token = await authLocalDataSource.getAccessToken();
    if (token == null) {
      return const Left(UnauthorizedFailure('Please login to get summary'));
    }

    // Try to get from cache first
    final cachedSummary = await localDataSource.getCachedSummary(transcriptionId);
    if (cachedSummary != null) {
      return Right(cachedSummary);
    }

    if (await networkInfo.isConnected) {
      try {
        final summaryModel = await remoteDataSource.getSummary(transcriptionId);
        // Cache the summary
        await localDataSource.cacheSummary(transcriptionId, summaryModel);
        return Right(summaryModel);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, Summary>> saveSummary(Summary summary) async {
    // Check if user is authenticated
    final token = await authLocalDataSource.getAccessToken();
    if (token == null) {
      return const Left(UnauthorizedFailure('Please login to save summary'));
    }

    if (await networkInfo.isConnected) {
      try {
        final summaryModel = SummaryModel.fromEntity(summary);
        final savedSummary = await remoteDataSource.saveSummary(summaryModel);
        // Update cache using summaryId
        await localDataSource.cacheSummary(summary.summaryId, savedSummary);
        return Right(savedSummary);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, Summary>> resummarize(String transcriptionId) async {
    // Check if user is authenticated
    final token = await authLocalDataSource.getAccessToken();
    if (token == null) {
      return const Left(UnauthorizedFailure('Please login to resummarize'));
    }

    if (await networkInfo.isConnected) {
      try {
        final summaryModel = await remoteDataSource.resummarize(transcriptionId);
        // Update cache
        await localDataSource.cacheSummary(transcriptionId, summaryModel);
        return Right(summaryModel);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, Summary>> updateActionItem(
    String summaryId,
    String actionItemId,
    bool isCompleted,
  ) async {
    // Check if user is authenticated
    final token = await authLocalDataSource.getAccessToken();
    if (token == null) {
      return const Left(UnauthorizedFailure('Please login to update action item'));
    }

    if (await networkInfo.isConnected) {
      try {
        final summaryModel = await remoteDataSource.updateActionItem(
          summaryId,
          actionItemId,
          isCompleted,
        );
        // Update cache if we have a transcription ID
        await localDataSource.cacheSummary(summaryId, summaryModel);
        return Right(summaryModel);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, Summary>> summarizeRecording({
    required String recordingId,
    String? summaryStyle,
  }) async {
    final token = await authLocalDataSource.getAccessToken();
    if (token == null) {
      return const Left(UnauthorizedFailure('Please login to summarize recording'));
    }

    if (await networkInfo.isConnected) {
      try {
        final summaryModel = await remoteDataSource.summarizeRecording(
          recordingId: recordingId,
          summaryStyle: summaryStyle,
        );
        return Right(summaryModel);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, List<Summary>>> getSummaries({
    required String recordingId,
    bool? latest,
  }) async {
    final token = await authLocalDataSource.getAccessToken();
    if (token == null) {
      return const Left(UnauthorizedFailure('Please login to get summaries'));
    }

    if (await networkInfo.isConnected) {
      try {
        final summaryModels = await remoteDataSource.getSummaries(
          recordingId: recordingId,
          latest: latest,
        );
        return Right(summaryModels);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, Summary>> getSummaryDetail(String summaryId) async {
    final token = await authLocalDataSource.getAccessToken();
    if (token == null) {
      return const Left(UnauthorizedFailure('Please login to get summary detail'));
    }

    if (await networkInfo.isConnected) {
      try {
        final summaryModel = await remoteDataSource.getSummaryDetail(summaryId);
        return Right(summaryModel);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, Summary>> updateSummary({
    required String summaryId,
    Map<String, dynamic>? contentStructure,
    String? type,
    bool? isLatest,
  }) async {
    final token = await authLocalDataSource.getAccessToken();
    if (token == null) {
      return const Left(UnauthorizedFailure('Please login to update summary'));
    }

    if (await networkInfo.isConnected) {
      try {
        final summaryModel = await remoteDataSource.updateSummary(
          summaryId: summaryId,
          contentStructure: contentStructure,
          type: type,
          isLatest: isLatest,
        );
        return Right(summaryModel);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, Summary?>> getLatestSummaryForRecording(
    String recordingId,
  ) async {
    final token = await authLocalDataSource.getAccessToken();
    if (token == null) {
      return const Left(
        UnauthorizedFailure('Please login to get summary for recording'),
      );
    }

    if (await networkInfo.isConnected) {
      try {
        // Step 1: Check if summary already exists
        String? summaryId;
        try {
          summaryId = await remoteDataSource.fetchLatestSummaryId(recordingId);
        } catch (e) {
          // If fetch fails with auth error, return auth failure
          if (e.toString().contains('Authentication failed')) {
            return const Left(
              UnauthorizedFailure('Authentication failed. Please try again.'),
            );
          }
          // For other errors, continue to try generating
        }
        
        // Step 2: If no summary exists, trigger generation
        if (summaryId == null) {
          try {
            await remoteDataSource.generateSummary(recordingId);
          } catch (e) {
            // If generation fails with auth error, return auth failure
            if (e.toString().contains('Authentication failed') ||
                e.toString().contains('401')) {
              return const Left(
                UnauthorizedFailure('Authentication failed. Please try again.'),
              );
            }
            // For other errors, still try to poll (maybe generation is in progress)
          }

          // Step 3: Poll for summary with retries (summary generation is async)
          const maxRetries = 10;
          const retryDelay = Duration(seconds: 2);
          
          for (int attempt = 0; attempt < maxRetries; attempt++) {
            // Wait before checking (except on first attempt)
            if (attempt > 0) {
              await Future.delayed(retryDelay);
            }
            
            try {
              summaryId = await remoteDataSource.fetchLatestSummaryId(recordingId);
              if (summaryId != null) {
                break; // Summary is ready
              }
            } catch (e) {
              // If auth error during polling, return auth failure
              if (e.toString().contains('Authentication failed') ||
                  e.toString().contains('401')) {
                return const Left(
                  UnauthorizedFailure('Authentication failed. Please try again.'),
                );
              }
              // For other errors, continue polling
            }
          }

          // If still no summary after retries, return null
          if (summaryId == null) {
            return const Right(null);
          }
        }

        // Step 4: Fetch full summary content
        try {
          final summaryModel = await remoteDataSource.fetchSummary(summaryId);
          return Right(summaryModel);
        } catch (e) {
          // If auth error when fetching summary, return auth failure
          if (e.toString().contains('Authentication failed') ||
              e.toString().contains('401')) {
            return const Left(
              UnauthorizedFailure('Authentication failed. Please try again.'),
            );
          }
          return Left(ServerFailure('Failed to fetch summary: $e'));
        }
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }
}

