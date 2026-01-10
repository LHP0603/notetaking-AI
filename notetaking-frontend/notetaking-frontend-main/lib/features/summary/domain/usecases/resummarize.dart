import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/summary.dart';
import '../repositories/summary_repository.dart';

class Resummarize {
  final SummaryRepository repository;

  Resummarize(this.repository);

  Future<Either<Failure, Summary>> call(String transcriptionId) async {
    return await repository.resummarize(transcriptionId);
  }
}

