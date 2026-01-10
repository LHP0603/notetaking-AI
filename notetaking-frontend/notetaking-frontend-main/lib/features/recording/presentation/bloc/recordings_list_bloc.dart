import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/recording_repository.dart';
import '../../../folder/domain/repositories/folder_repository.dart';
import 'recordings_list_event.dart';
import 'recordings_list_state.dart';

class RecordingsListBloc
    extends Bloc<RecordingsListEvent, RecordingsListState> {
  final RecordingRepository recordingRepository;
  final FolderRepository folderRepository;

  static const int _pageSize = 20;
  Timer? _searchDebounceTimer;

  RecordingsListBloc({
    required this.recordingRepository,
    required this.folderRepository,
  }) : super(RecordingsListInitial()) {
    on<RecordingsListStarted>(_onStarted);
    on<FolderSelected>(_onFolderSelected);
    on<SearchChanged>(_onSearchChanged);
    on<LoadMoreRecordings>(_onLoadMore);
    on<CreateFolderRequested>(_onCreateFolder);
    on<RefreshRecordings>(_onRefresh);
  }

  Future<void> _onStarted(
    RecordingsListStarted event,
    Emitter<RecordingsListState> emit,
  ) async {
    emit(RecordingsListLoading());

    // Load folders and recordings in parallel
    final foldersResult = await folderRepository.getFolders();
    final recordingsResult = await recordingRepository.getRecordings(
      page: 1,
      pageSize: _pageSize,
      isTrashed: false,
    );

    foldersResult.fold(
      (failure) {
        recordingsResult.fold(
          (recFailure) => emit(
            RecordingsListError(message: 'Failed to load: ${failure.message}'),
          ),
          (recordings) => emit(
            RecordingsListError(
              message: 'Failed to load folders: ${failure.message}',
              recordings: recordings,
            ),
          ),
        );
      },
      (folders) {
        recordingsResult.fold(
          (failure) => emit(
            RecordingsListError(
              message: 'Failed to load recordings: ${failure.message}',
              folders: folders,
            ),
          ),
          (recordings) => emit(
            RecordingsListLoaded(
              folders: folders,
              recordings: recordings,
              currentPage: 1,
              hasMore: recordings.length == _pageSize,
            ),
          ),
        );
      },
    );
  }

  Future<void> _onFolderSelected(
    FolderSelected event,
    Emitter<RecordingsListState> emit,
  ) async {
    if (state is! RecordingsListLoaded) return;
    final currentState = state as RecordingsListLoaded;

    emit(
      currentState.copyWith(
        selectedFolderId: event.folderId,
        currentPage: 1,
        isLoadingMore: true,
      ),
    );

    final result = await recordingRepository.getRecordings(
      folderId: event.folderId,
      search: currentState.searchText.isEmpty ? null : currentState.searchText,
      page: 1,
      pageSize: _pageSize,
      isTrashed: false,
    );

    result.fold(
      (failure) => emit(
        RecordingsListError(
          message: failure.message,
          folders: currentState.folders,
          recordings: currentState.recordings,
        ),
      ),
      (recordings) => emit(
        currentState.copyWith(
          selectedFolderId: event.folderId,
          recordings: recordings,
          currentPage: 1,
          hasMore: recordings.length == _pageSize,
          isLoadingMore: false,
        ),
      ),
    );
  }

  void _onSearchChanged(
    SearchChanged event,
    Emitter<RecordingsListState> emit,
  ) {
    // Cancel previous timer
    _searchDebounceTimer?.cancel();

    // Debounce search by 400ms
    _searchDebounceTimer = Timer(const Duration(milliseconds: 400), () {
      _performSearch(event.searchText, emit);
    });
  }

  Future<void> _performSearch(
    String searchText,
    Emitter<RecordingsListState> emit,
  ) async {
    if (state is! RecordingsListLoaded) return;
    final currentState = state as RecordingsListLoaded;

    emit(
      currentState.copyWith(
        searchText: searchText,
        currentPage: 1,
        isLoadingMore: true,
      ),
    );

    final result = await recordingRepository.getRecordings(
      folderId: currentState.selectedFolderId,
      search: searchText.isEmpty ? null : searchText,
      page: 1,
      pageSize: _pageSize,
      isTrashed: false,
    );

    result.fold(
      (failure) => emit(
        RecordingsListError(
          message: failure.message,
          folders: currentState.folders,
          recordings: currentState.recordings,
        ),
      ),
      (recordings) => emit(
        currentState.copyWith(
          searchText: searchText,
          recordings: recordings,
          currentPage: 1,
          hasMore: recordings.length == _pageSize,
          isLoadingMore: false,
        ),
      ),
    );
  }

  Future<void> _onLoadMore(
    LoadMoreRecordings event,
    Emitter<RecordingsListState> emit,
  ) async {
    if (state is! RecordingsListLoaded) return;
    final currentState = state as RecordingsListLoaded;

    if (!currentState.hasMore || currentState.isLoadingMore) return;

    emit(currentState.copyWith(isLoadingMore: true));

    final nextPage = currentState.currentPage + 1;
    final result = await recordingRepository.getRecordings(
      folderId: currentState.selectedFolderId,
      search: currentState.searchText.isEmpty ? null : currentState.searchText,
      page: nextPage,
      pageSize: _pageSize,
      isTrashed: false,
    );

    result.fold(
      (failure) => emit(currentState.copyWith(isLoadingMore: false)),
      (newRecordings) => emit(
        currentState.copyWith(
          recordings: [...currentState.recordings, ...newRecordings],
          currentPage: nextPage,
          hasMore: newRecordings.length == _pageSize,
          isLoadingMore: false,
        ),
      ),
    );
  }

  Future<void> _onCreateFolder(
    CreateFolderRequested event,
    Emitter<RecordingsListState> emit,
  ) async {
    if (state is! RecordingsListLoaded) return;
    final currentState = state as RecordingsListLoaded;

    final result = await folderRepository.createFolder(
      name: event.name,
      parentFolderId: event.parentFolderId,
    );

    result.fold(
      (failure) => emit(
        RecordingsListError(
          message: 'Failed to create folder: ${failure.message}',
          folders: currentState.folders,
          recordings: currentState.recordings,
        ),
      ),
      (newFolder) {
        // Refresh folders list
        folderRepository.getFolders().then((foldersResult) {
          foldersResult.fold((failure) {}, (folders) {
            if (state is RecordingsListLoaded) {
              emit((state as RecordingsListLoaded).copyWith(folders: folders));
            }
          });
        });
      },
    );
  }

  Future<void> _onRefresh(
    RefreshRecordings event,
    Emitter<RecordingsListState> emit,
  ) async {
    if (state is! RecordingsListLoaded) return;
    final currentState = state as RecordingsListLoaded;

    emit(currentState.copyWith(isLoadingMore: true));

    final result = await recordingRepository.getRecordings(
      folderId: currentState.selectedFolderId,
      search: currentState.searchText.isEmpty ? null : currentState.searchText,
      page: 1,
      pageSize: _pageSize,
      isTrashed: false,
    );

    result.fold(
      (failure) => emit(
        RecordingsListError(
          message: failure.message,
          folders: currentState.folders,
          recordings: currentState.recordings,
        ),
      ),
      (recordings) => emit(
        currentState.copyWith(
          recordings: recordings,
          currentPage: 1,
          hasMore: recordings.length == _pageSize,
          isLoadingMore: false,
        ),
      ),
    );
  }

  @override
  Future<void> close() {
    _searchDebounceTimer?.cancel();
    return super.close();
  }
}
