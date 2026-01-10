import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/folder_repository.dart';

class DeleteFolder {
  final FolderRepository repository;

  DeleteFolder(this.repository);

  Future<Either<Failure, void>> call(String folderId) async {
    return await repository.deleteFolder(folderId);
  }
}


