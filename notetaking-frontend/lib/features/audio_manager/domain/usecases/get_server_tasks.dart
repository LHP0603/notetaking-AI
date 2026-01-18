import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/usecase.dart';
import '../entities/server_task_bucket.dart';
import '../repositories/audio_manager_repository.dart';

class GetServerTasks
    implements UseCase<Either<Failure, ServerTaskBucket>, NoParams> {
  final AudioManagerRepository repository;

  GetServerTasks(this.repository);

  @override
  Future<Either<Failure, ServerTaskBucket>> call(NoParams params) async {
    return await repository.getServerTasks();
  }
}
