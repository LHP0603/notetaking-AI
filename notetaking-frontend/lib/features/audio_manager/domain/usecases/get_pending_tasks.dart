import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/usecase.dart';
import '../entities/pending_task_bucket.dart';
import '../repositories/audio_manager_repository.dart';

class GetPendingTasks
    implements UseCase<Either<Failure, PendingTaskBucket>, NoParams> {
  final AudioManagerRepository repository;

  GetPendingTasks(this.repository);

  @override
  Future<Either<Failure, PendingTaskBucket>> call(NoParams params) async {
    return await repository.getPendingTasks();
  }
}
