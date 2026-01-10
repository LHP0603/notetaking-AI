import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/export_job.dart';
import '../../domain/repositories/export_repository.dart';
import '../datasources/export_remote_data_source.dart';
import '../../../auth/data/datasources/auth_local_data_source.dart';

class ExportRepositoryImpl implements ExportRepository {
  final ExportRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;
  final AuthLocalDataSource authLocalDataSource;

  ExportRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
    required this.authLocalDataSource,
  });

  @override
  Future<Either<Failure, ExportJob>> createExportJob({
    required String recordingId,
    required String exportType,
  }) async {
    final token = await authLocalDataSource.getAccessToken();
    if (token == null) {
      return const Left(UnauthorizedFailure('Please login to create export job'));
    }

    if (await networkInfo.isConnected) {
      try {
        final job = await remoteDataSource.createExportJob(
          recordingId: recordingId,
          exportType: exportType,
        );
        return Right(job);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('Failed to create export job: $e'));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, ExportJob>> getExportJobStatus(int jobId) async {
    final token = await authLocalDataSource.getAccessToken();
    if (token == null) {
      return const Left(UnauthorizedFailure('Please login to get export job status'));
    }

    if (await networkInfo.isConnected) {
      try {
        final job = await remoteDataSource.getExportJobStatus(jobId);
        return Right(job);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('Failed to get export job status: $e'));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }
}

