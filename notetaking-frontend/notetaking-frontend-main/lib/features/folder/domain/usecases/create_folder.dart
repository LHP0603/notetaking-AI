import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/folder.dart';
import '../repositories/folder_repository.dart';

class CreateFolder {
  final FolderRepository repository;

  CreateFolder(this.repository);

  Future<Either<Failure, Folder>> call({
    required String name,
    String? parentFolderId,
  }) async {
    return await repository.createFolder(
      name: name,
      parentFolderId: parentFolderId,
    );
  }
}


