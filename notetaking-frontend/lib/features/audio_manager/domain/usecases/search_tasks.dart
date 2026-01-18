import 'package:dartz/dartz.dart' hide Task;
import '../../../../core/errors/failures.dart';
import '../entities/task.dart';
import '../entities/task_search_criteria.dart';
import '../repositories/audio_manager_repository.dart';

class SearchTasks {
  final AudioManagerRepository repository;

  SearchTasks(this.repository);

  Future<Either<Failure, List<Task>>> call(
    TaskSearchCriteria criteria,
  ) async {
    return await repository.searchTasks(criteria);
  }
}
