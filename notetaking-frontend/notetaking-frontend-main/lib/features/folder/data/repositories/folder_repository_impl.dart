import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../auth/data/datasources/auth_local_data_source.dart';
import '../../domain/entities/folder.dart';
import '../../domain/repositories/folder_repository.dart';
import '../datasources/folder_remote_data_source.dart';

class FolderRepositoryImpl implements FolderRepository {
  final FolderRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;
  final AuthLocalDataSource authLocalDataSource;

  FolderRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
    required this.authLocalDataSource,
  });

  @override
  Future<Either<Failure, Folder>> createFolder({
    required String name,
    String? parentFolderId,
  }) async {
    final token = await authLocalDataSource.getAccessToken();
    if (token == null) {
      return const Left(UnauthorizedFailure('Please login to create folder'));
    }

    if (await networkInfo.isConnected) {
      try {
        final folder = await remoteDataSource.createFolder(
          name: name,
          parentFolderId: parentFolderId,
        );
        return Right(folder);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, List<Folder>>> getFolders({
    String? parentFolderId,
  }) async {
    final token = await authLocalDataSource.getAccessToken();
    if (token == null) {
      return const Left(UnauthorizedFailure('Please login to get folders'));
    }

    if (await networkInfo.isConnected) {
      try {
        final folders = await remoteDataSource.getFolders(
          parentFolderId: parentFolderId,
        );
        return Right(folders);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, Folder>> updateFolder({
    required String folderId,
    String? name,
    String? parentFolderId,
  }) async {
    final token = await authLocalDataSource.getAccessToken();
    if (token == null) {
      return const Left(UnauthorizedFailure('Please login to update folder'));
    }

    if (await networkInfo.isConnected) {
      try {
        final folder = await remoteDataSource.updateFolder(
          folderId: folderId,
          name: name,
          parentFolderId: parentFolderId,
        );
        return Right(folder);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteFolder(String folderId) async {
    final token = await authLocalDataSource.getAccessToken();
    if (token == null) {
      return const Left(UnauthorizedFailure('Please login to delete folder'));
    }

    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.deleteFolder(folderId);
        return const Right(null);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }
}


