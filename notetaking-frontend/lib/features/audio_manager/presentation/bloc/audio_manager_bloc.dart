import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/usecase.dart';
import '../../domain/entities/audio_filter.dart';
import '../../domain/usecases/filter_audios.dart';
import '../../domain/usecases/get_pending_tasks.dart';
import '../../domain/usecases/get_server_tasks.dart';
import '../../domain/usecases/get_uploaded_audios.dart';
import '../../domain/usecases/search_audios.dart' as search_usecase;
import '../../domain/usecases/upload_audio_file.dart' as upload_usecase;
import 'audio_manager_event.dart';
import 'audio_manager_state.dart';
import 'pending_audio_type.dart';

class AudioManagerBloc extends Bloc<AudioManagerEvent, AudioManagerState> {
  final GetUploadedAudios getUploadedAudios;
  final upload_usecase.UploadAudioFile uploadAudioFile;
  final GetServerTasks getServerTasks;
  final GetPendingTasks getPendingTasks;
  final search_usecase.SearchAudios searchAudios;
  final FilterAudios filterAudios;

  AudioManagerBloc({
    required this.getUploadedAudios,
    required this.uploadAudioFile,
    required this.getServerTasks,
    required this.getPendingTasks,
    required this.searchAudios,
    required this.filterAudios,
  }) : super(AudioManagerState.initial()) {
    on<LoadUploadedAudios>(_onLoadUploadedAudios);
    on<UploadAudioFile>(_onUploadAudioFile);
    on<LoadServerTasks>(_onLoadServerTasks);
    on<LoadPendingTasks>(_onLoadPendingTasks);
    on<LoadPendingAudios>(_onLoadPendingAudios);
    on<SearchPendingAudios>(_onSearchPendingAudios);
    on<LoadMorePendingAudios>(_onLoadMorePendingAudios);
    on<SearchAudios>(_onSearchAudios);
    on<ApplyFilter>(_onApplyFilter);
    on<RefreshAllData>(_onRefreshAllData);
    on<LoadMoreAudios>(_onLoadMoreAudios);
    on<ClearMessage>(_onClearMessage);
  }

  Future<void> _onLoadUploadedAudios(
    LoadUploadedAudios event,
    Emitter<AudioManagerState> emit,
  ) async {
    emit(state.copyWith(isLoadingAudios: true, errorMessage: null));

    final searchQuery = event.searchQuery ?? state.searchQuery;
    final fromDate = event.fromDate ?? state.fromDate;
    final toDate = event.toDate ?? state.toDate;
    const page = 1;

    final result = await getUploadedAudios(
      AudioFilter(
        search: searchQuery.isEmpty ? null : searchQuery,
        fromDate: fromDate,
        toDate: toDate,
        page: page,
        limit: state.limit,
      ),
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          isLoadingAudios: false,
          errorMessage: failure.message,
          searchQuery: searchQuery,
          fromDate: fromDate,
          toDate: toDate,
          page: page,
          hasMoreAudios: true,
        ),
      ),
      (page) => emit(
        state.copyWith(
          isLoadingAudios: false,
          audios: page.items,
          totalCount: page.total,
          searchQuery: searchQuery,
          fromDate: fromDate,
          toDate: toDate,
          page: page.page,
          limit: page.limit,
          hasMoreAudios:
              page.hasNextPage ?? page.items.length < page.total,
        ),
      ),
    );
  }

  Future<void> _onSearchAudios(
    SearchAudios event,
    Emitter<AudioManagerState> emit,
  ) async {
    emit(state.copyWith(isLoadingAudios: true, errorMessage: null));

    final result = await searchAudios(
      search_usecase.SearchAudiosParams(
        query: event.query,
        fromDate: state.fromDate,
        toDate: state.toDate,
        page: 1,
        limit: state.limit,
      ),
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          isLoadingAudios: false,
          errorMessage: failure.message,
          searchQuery: event.query,
          page: 1,
          hasMoreAudios: true,
        ),
      ),
      (page) => emit(
        state.copyWith(
          isLoadingAudios: false,
          audios: page.items,
          totalCount: page.total,
          searchQuery: event.query,
          page: page.page,
          limit: page.limit,
          hasMoreAudios:
              page.hasNextPage ?? page.items.length < page.total,
        ),
      ),
    );
  }

  Future<void> _onApplyFilter(
    ApplyFilter event,
    Emitter<AudioManagerState> emit,
  ) async {
    emit(state.copyWith(isLoadingAudios: true, errorMessage: null));

    final result = await filterAudios(
      FilterAudiosParams(
        search: state.searchQuery.isEmpty ? null : state.searchQuery,
        fromDate: event.fromDate,
        toDate: event.toDate,
        page: 1,
        limit: state.limit,
      ),
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          isLoadingAudios: false,
          errorMessage: failure.message,
          fromDate: event.fromDate,
          toDate: event.toDate,
          page: 1,
          hasMoreAudios: true,
        ),
      ),
      (page) => emit(
        state.copyWith(
          isLoadingAudios: false,
          audios: page.items,
          totalCount: page.total,
          fromDate: event.fromDate,
          toDate: event.toDate,
          page: page.page,
          limit: page.limit,
          hasMoreAudios:
              page.hasNextPage ?? page.items.length < page.total,
        ),
      ),
    );
  }

  Future<void> _onUploadAudioFile(
    UploadAudioFile event,
    Emitter<AudioManagerState> emit,
  ) async {
    emit(
      state.copyWith(
        isUploading: true,
        uploadProgress: 0,
        errorMessage: null,
        successMessage: null,
      ),
    );

    final result = await uploadAudioFile(event.audioFile);

    await result.fold(
      (failure) async {
        emit(
          state.copyWith(
            isUploading: false,
            uploadProgress: 0,
            errorMessage: failure.message,
          ),
        );
      },
      (upload) async {
        emit(
          state.copyWith(
            isUploading: false,
            uploadProgress: 1,
            successMessage:
                'Upload started for ${upload.filename}. Check Tasks tab.',
          ),
        );
        add(
          LoadUploadedAudios(
            searchQuery: state.searchQuery,
            fromDate: state.fromDate,
            toDate: state.toDate,
          ),
        );
      },
    );
  }

  Future<void> _onLoadServerTasks(
    LoadServerTasks event,
    Emitter<AudioManagerState> emit,
  ) async {
    emit(state.copyWith(isLoadingTasks: true, errorMessage: null));

    final result = await getServerTasks(NoParams());

    result.fold(
      (failure) => emit(
        state.copyWith(
          isLoadingTasks: false,
          errorMessage: failure.message,
        ),
      ),
      (bucket) => emit(
        state.copyWith(
          isLoadingTasks: false,
          uploadingTasks: bucket.uploading,
          transcribingTasks: bucket.transcribing,
          summarizingTasks: bucket.summarizing,
        ),
      ),
    );
  }

  Future<void> _onLoadPendingTasks(
    LoadPendingTasks event,
    Emitter<AudioManagerState> emit,
  ) async {
    emit(state.copyWith(isLoadingPending: true, errorMessage: null));

    final result = await getPendingTasks(NoParams());

    result.fold(
      (failure) => emit(
        state.copyWith(
          isLoadingPending: false,
          errorMessage: failure.message,
        ),
      ),
      (bucket) => emit(
        state.copyWith(
          isLoadingPending: false,
          untranscribedAudios: bucket.untranscribedAudios,
          unsummarizedTranscripts: bucket.unsummarizedTranscripts,
        ),
      ),
    );
  }

  Future<void> _onLoadPendingAudios(
    LoadPendingAudios event,
    Emitter<AudioManagerState> emit,
  ) async {
    emit(
      state.copyWith(
        isLoadingPendingAudios: true,
        pendingErrorMessage: null,
      ),
    );

    final untranscribedResult = await getUploadedAudios(
      _pendingFilter(
        type: PendingAudioType.untranscribed,
        page: 1,
        limit: 3,
      ),
    );

    final unsummarizedResult = await getUploadedAudios(
      _pendingFilter(
        type: PendingAudioType.unsummarized,
        page: 1,
        limit: 3,
      ),
    );

    untranscribedResult.fold(
      (failure) => emit(
        state.copyWith(
          isLoadingPendingAudios: false,
          pendingErrorMessage: failure.message,
        ),
      ),
      (untranscribedPage) {
        unsummarizedResult.fold(
          (failure) => emit(
            state.copyWith(
              isLoadingPendingAudios: false,
              pendingErrorMessage: failure.message,
            ),
          ),
          (unsummarizedPage) => emit(
            state.copyWith(
              isLoadingPendingAudios: false,
              pendingUntranscribedAudios: untranscribedPage.items,
              pendingUnsummarizedAudios: unsummarizedPage.items,
              pendingUntranscribedCount: untranscribedPage.total,
              pendingUnsummarizedCount: unsummarizedPage.total,
              pendingErrorMessage: null,
            ),
          ),
        );
      },
    );
  }

  Future<void> _onSearchPendingAudios(
    SearchPendingAudios event,
    Emitter<AudioManagerState> emit,
  ) async {
    final normalizedSearch = (event.searchQuery ?? '').trim();
    final search =
        normalizedSearch.isEmpty ? null : normalizedSearch;

    emit(
      state.copyWith(
        pendingDetailIsLoading: true,
        pendingDetailIsLoadingMore: false,
        pendingDetailType: event.type,
        pendingDetailAudios: const [],
        pendingDetailHasMore: true,
        pendingDetailPage: 1,
        pendingDetailSearchQuery: normalizedSearch,
        pendingDetailFromDate: event.fromDate,
        pendingDetailToDate: event.toDate,
        pendingErrorMessage: null,
      ),
    );

    final result = await getUploadedAudios(
      _pendingFilter(
        type: event.type,
        page: 1,
        limit: 10,
        search: search,
        fromDate: event.fromDate,
        toDate: event.toDate,
      ),
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          pendingDetailIsLoading: false,
          pendingErrorMessage: failure.message,
        ),
      ),
      (page) => emit(
        state.copyWith(
          pendingDetailIsLoading: false,
          pendingDetailAudios: page.items,
          pendingDetailPage: page.page,
          pendingDetailHasMore:
              page.hasNextPage ?? page.items.length < page.total,
          pendingErrorMessage: null,
        ),
      ),
    );
  }

  Future<void> _onLoadMorePendingAudios(
    LoadMorePendingAudios event,
    Emitter<AudioManagerState> emit,
  ) async {
    if (state.pendingDetailType != event.type ||
        state.pendingDetailIsLoading ||
        state.pendingDetailIsLoadingMore ||
        !state.pendingDetailHasMore) {
      return;
    }

    emit(
      state.copyWith(
        pendingDetailIsLoadingMore: true,
        pendingErrorMessage: null,
      ),
    );

    final nextPage = state.pendingDetailPage + 1;
    final normalizedSearch = state.pendingDetailSearchQuery.trim();
    final search =
        normalizedSearch.isEmpty ? null : normalizedSearch;

    final result = await getUploadedAudios(
      _pendingFilter(
        type: event.type,
        page: nextPage,
        limit: 10,
        search: search,
        fromDate: state.pendingDetailFromDate,
        toDate: state.pendingDetailToDate,
      ),
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          pendingDetailIsLoadingMore: false,
          pendingErrorMessage: failure.message,
        ),
      ),
      (page) => emit(
        state.copyWith(
          pendingDetailIsLoadingMore: false,
          pendingDetailAudios: [
            ...state.pendingDetailAudios,
            ...page.items,
          ],
          pendingDetailPage: page.page,
          pendingDetailHasMore:
              page.hasNextPage ?? page.items.length < page.total,
          pendingErrorMessage: null,
        ),
      ),
    );
  }

  void _onRefreshAllData(
    RefreshAllData event,
    Emitter<AudioManagerState> emit,
  ) {
    add(
      LoadUploadedAudios(
        searchQuery: state.searchQuery,
        fromDate: state.fromDate,
        toDate: state.toDate,
      ),
    );
    add(const LoadPendingAudios());
  }

  Future<void> _onLoadMoreAudios(
    LoadMoreAudios event,
    Emitter<AudioManagerState> emit,
  ) async {
    if (state.isLoadingMore || !state.hasMoreAudios) {
      return;
    }

    final nextPage = state.page + 1;
    emit(state.copyWith(isLoadingMore: true, errorMessage: null));

    final result = await getUploadedAudios(
      AudioFilter(
        search: state.searchQuery.isEmpty ? null : state.searchQuery,
        fromDate: state.fromDate,
        toDate: state.toDate,
        page: nextPage,
        limit: state.limit,
      ),
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          isLoadingMore: false,
          errorMessage: failure.message,
        ),
      ),
      (page) => emit(
        state.copyWith(
          isLoadingMore: false,
          audios: [...state.audios, ...page.items],
          totalCount: page.total,
          page: page.page,
          limit: page.limit,
          hasMoreAudios:
              page.hasNextPage ??
              state.audios.length + page.items.length < page.total,
        ),
      ),
    );
  }

  void _onClearMessage(
    ClearMessage event,
    Emitter<AudioManagerState> emit,
  ) {
    emit(state.copyWith(errorMessage: null, successMessage: null));
  }

  AudioFilter _pendingFilter({
    required PendingAudioType type,
    required int page,
    required int limit,
    String? search,
    DateTime? fromDate,
    DateTime? toDate,
  }) {
    return AudioFilter(
      search: search,
      fromDate: fromDate,
      toDate: toDate,
      hasTranscript: type == PendingAudioType.untranscribed ? false : true,
      hasSummary: type == PendingAudioType.unsummarized ? false : null,
      order: 'DESC',
      page: page,
      limit: limit,
      status: 'completed',
    );
  }
}
