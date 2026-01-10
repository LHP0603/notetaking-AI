import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/folder.dart';
import '../repositories/folder_repository.dart';

class UpdateFolder {
  final FolderRepository repository;

  UpdateFolder(this.repository);

  Future<Either<Failure, Folder>> call({
    required String folderId,
    String? name,
    String? parentFolderId,
  }) async {
    return await repository.updateFolder(
      folderId: folderId,
      name: name,
      parentFolderId: parentFolderId,
    );
  }
}


