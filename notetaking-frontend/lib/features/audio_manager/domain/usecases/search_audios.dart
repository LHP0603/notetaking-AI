import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/usecase.dart';
import '../entities/audio_file_page.dart';
import '../entities/audio_filter.dart';
import '../repositories/audio_manager_repository.dart';

class SearchAudios
    implements UseCase<Either<Failure, AudioFilePage>, SearchAudiosParams> {
  final AudioManagerRepository repository;

  SearchAudios(this.repository);

  @override
  Future<Either<Failure, AudioFilePage>> call(
    SearchAudiosParams params,
  ) async {
    return await repository.getUploadedAudios(
      AudioFilter(
        search: params.query,
        fromDate: params.fromDate,
        toDate: params.toDate,
        page: params.page,
        limit: params.limit,
      ),
    );
  }
}

class SearchAudiosParams extends Equatable {
  final String query;
  final DateTime? fromDate;
  final DateTime? toDate;
  final int page;
  final int limit;

  const SearchAudiosParams({
    required this.query,
    this.fromDate,
    this.toDate,
    this.page = 1,
    this.limit = 10,
  });

  @override
  List<Object?> get props => [query, fromDate, toDate, page, limit];
}
