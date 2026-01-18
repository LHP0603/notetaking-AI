import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/summary.dart';

abstract class SummaryRepository {
  Future<Either<Failure, Summary>> getSummary(String transcriptionId);
  Future<Either<Failure, Summary>> saveSummary(Summary summary);
  Future<Either<Failure, Summary>> resummarize(String transcriptionId);
  Future<Either<Failure, Summary>> updateActionItem(
    String summaryId,
    String actionItemId,
    bool isCompleted,
  );
}

