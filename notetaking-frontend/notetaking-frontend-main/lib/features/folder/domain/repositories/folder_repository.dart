import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/folder.dart';

abstract class FolderRepository {
  Future<Either<Failure, Folder>> createFolder({
    required String name,
    String? parentFolderId,
  });
  Future<Either<Failure, List<Folder>>> getFolders({String? parentFolderId});
  Future<Either<Failure, Folder>> updateFolder({
    required String folderId,
    String? name,
    String? parentFolderId,
  });
  Future<Either<Failure, void>> deleteFolder(String folderId);
}


