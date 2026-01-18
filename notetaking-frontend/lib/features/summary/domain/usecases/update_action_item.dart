import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/summary.dart';
import '../repositories/summary_repository.dart';

class UpdateActionItem {
  final SummaryRepository repository;

  UpdateActionItem(this.repository);

  Future<Either<Failure, Summary>> call({
    required String summaryId,
    required String actionItemId,
    required bool isCompleted,
  }) async {
    return await repository.updateActionItem(
      summaryId,
      actionItemId,
      isCompleted,
    );
  }
}

