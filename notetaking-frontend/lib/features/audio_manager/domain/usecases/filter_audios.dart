import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/usecase.dart';
import '../entities/audio_file_page.dart';
import '../entities/audio_filter.dart';
import '../repositories/audio_manager_repository.dart';

class FilterAudios
    implements UseCase<Either<Failure, AudioFilePage>, FilterAudiosParams> {
  final AudioManagerRepository repository;

  FilterAudios(this.repository);

  @override
  Future<Either<Failure, AudioFilePage>> call(
    FilterAudiosParams params,
  ) async {
    return await repository.getUploadedAudios(
      AudioFilter(
        search: params.search,
        fromDate: params.fromDate,
        toDate: params.toDate,
        page: params.page,
        limit: params.limit,
      ),
    );
  }
}

class FilterAudiosParams extends Equatable {
  final String? search;
  final DateTime? fromDate;
  final DateTime? toDate;
  final int page;
  final int limit;

  const FilterAudiosParams({
    this.search,
    this.fromDate,
    this.toDate,
    this.page = 1,
    this.limit = 10,
  });

  @override
  List<Object?> get props => [search, fromDate, toDate, page, limit];
}
