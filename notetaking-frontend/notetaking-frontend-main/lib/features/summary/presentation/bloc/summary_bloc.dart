import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart' hide Summary;
import 'package:equatable/equatable.dart';
import '../../domain/usecases/get_summary.dart';
import '../../domain/usecases/save_summary.dart';
import '../../domain/usecases/resummarize.dart';
import '../../domain/usecases/update_action_item.dart';
import '../../domain/usecases/get_latest_summary_for_recording.dart';
import '../../../recording/domain/repositories/recording_repository.dart';
import '../../../recording/domain/entities/recording.dart';
import '../../../folder/domain/repositories/folder_repository.dart';
import '../../../folder/domain/entities/folder.dart';
import '../../data/datasources/summary_remote_data_source.dart';
import '../../domain/repositories/summary_repository.dart';
import '../../domain/entities/summary.dart';
import '../../../../core/errors/failures.dart';
import 'summary_event.dart';
import 'summary_state.dart';

class SummaryBloc extends Bloc<SummaryEvent, SummaryState> {
  final GetSummary getSummary;
  final SaveSummary saveSummary;
  final Resummarize resummarize;
  final UpdateActionItem updateActionItem;
  final GetLatestSummaryForRecording getLatestSummaryForRecording;
  final RecordingRepository recordingRepository;
  final FolderRepository folderRepository;
  final SummaryRepository summaryRepository;
  final SummaryRemoteDataSource summaryRemoteDataSource;

  // Cache for summaries list data
  SummariesListLoaded? _cachedSummariesList;
  // Cache for ALL summaries list data (unfiltered)
  SummariesListLoaded? _cachedAllSummariesList;
  // Cache for folders data
  List<Folder>? _cachedFolders;
  // Cache for trashed recordings
  List<Recording>? _cachedTrashedRecordings;

  SummaryBloc({
    required this.getSummary,
    required this.saveSummary,
    required this.resummarize,
    required this.updateActionItem,
    required this.getLatestSummaryForRecording,
    required this.recordingRepository,
    required this.folderRepository,
    required this.summaryRepository,
    required this.summaryRemoteDataSource,
  }) : super(SummaryInitial()) {
    on<GetSummaryEvent>(_onGetSummary);
    on<SaveSummaryEvent>(_onSaveSummary);
    on<ResummarizeEvent>(_onResummarize);
    on<UpdateActionItemEvent>(_onUpdateActionItem);
    on<ResetSummaryEvent>(_onReset);
    on<LoadSummaryForRecordingEvent>(_onLoadSummaryForRecording);
    on<ResummarizeRecordingEvent>(_onResummarizeRecording);
    on<ExportRecordingEvent>((event, emit) async {
      try {
        final currentSummary =
            (state is SummaryLoaded)
                ? (state as SummaryLoaded).summary
                : (state is RecordingSaved)
                ? (state as RecordingSaved).summary
                : (state is SummarySaving)
                ? (state as SummarySaving).summary
                : null;

        if (currentSummary == null) return;

        // Show loading state while keeping current content
        emit(ExportingSummary(currentSummary));

        // Start export job
        var job = await recordingRepository.exportRecording(
          event.recordingId,
          event.exportType,
        );

        // Poll for completion
        int attempts = 0;
        const maxAttempts = 30; // 30 * 2s = 60s timeout

        while (attempts < maxAttempts) {
          if (job.status == 'DONE') {
            if (job.downloadUrl != null) {
              emit(ExportSuccess(currentSummary, job.downloadUrl!));
            } else {
              // Fallback if no URL but DONE (shouldn't happen with current backend)
              emit(SummaryLoaded(currentSummary)); // Just stop loading
            }
            emit(SummaryLoaded(currentSummary));
            return;
          } else if (job.status == 'FAILED') {
            throw Exception('Export failed on server');
          }

          await Future.delayed(const Duration(seconds: 2));
          job = await recordingRepository.getExportJob(job.exportId);
          attempts++;
        }

        throw Exception('Export timed out');
      } catch (e) {
        final currentSummary =
            (state is ExportingSummary)
                ? (state as ExportingSummary).summary
                : null;
        if (currentSummary != null) {
          emit(SummaryLoaded(currentSummary));
        }
        debugPrint('Export error: $e');
        emit(SummaryLoaded(currentSummary!));
      }
    });

    on<SaveRecordingToFolderEvent>(_onSaveRecordingToFolder);
    on<LoadFoldersEvent>(_onLoadFolders);
    on<LoadSummariesListEvent>(_onLoadSummariesList);
    on<FolderChosenEvent>(_onFolderChosen);
    on<CreateFolderRequestedEvent>(_onCreateFolderRequested);
    on<FolderCreatedEvent>(_onFolderCreated);
    on<UpdateFolderEvent>(_onUpdateFolder);
    on<DeleteFolderEvent>(_onDeleteFolder);
    on<UpdateRecordingEvent>(_onUpdateRecording);
    on<DeleteRecordingEvent>(_onDeleteRecording);
    on<LoadTrashedRecordingsEvent>(_onLoadTrashedRecordings);
    on<RestoreRecordingEvent>(_onRestoreRecording);
    on<HardDeleteRecordingEvent>(_onHardDeleteRecording);
  }

  void _onGetSummary(GetSummaryEvent event, Emitter<SummaryState> emit) async {
    emit(SummaryLoading());

    final result = await getSummary(event.transcriptionId);

    result.fold(
      (failure) => emit(SummaryError(failure.message)),
      (summary) => emit(SummaryLoaded(summary)),
    );
  }

  void _onSaveSummary(
    SaveSummaryEvent event,
    Emitter<SummaryState> emit,
  ) async {
    emit(SummaryLoading());

    final result = await saveSummary(event.summary);

    result.fold(
      (failure) => emit(SummaryError(failure.message)),
      (summary) => emit(SummarySaved(summary)),
    );
  }

  void _onResummarize(
    ResummarizeEvent event,
    Emitter<SummaryState> emit,
  ) async {
    emit(SummaryLoading());

    final result = await resummarize(event.transcriptionId);

    result.fold(
      (failure) => emit(SummaryError(failure.message)),
      (summary) => emit(SummaryLoaded(summary)),
    );
  }

  void _onUpdateActionItem(
    UpdateActionItemEvent event,
    Emitter<SummaryState> emit,
  ) async {
    emit(SummaryLoading());

    final result = await updateActionItem(
      summaryId: event.summaryId,
      actionItemId: event.actionItemId,
      isCompleted: event.isCompleted,
    );

    result.fold(
      (failure) => emit(SummaryError(failure.message)),
      (summary) => emit(SummaryLoaded(summary)),
    );
  }

  void _onReset(ResetSummaryEvent event, Emitter<SummaryState> emit) {
    // Clear cache when resetting
    // Clear cache when resetting
    _cachedSummariesList = null;
    _cachedAllSummariesList = null;
    _cachedFolders = null;
    _cachedTrashedRecordings = null;
    emit(SummaryInitial());
  }

  void _onLoadSummaryForRecording(
    LoadSummaryForRecordingEvent event,
    Emitter<SummaryState> emit,
  ) async {
    emit(SummaryLoading());

    final result = await getLatestSummaryForRecording(event.recordingId);

    result.fold((failure) => emit(SummaryError(failure.message)), (summary) {
      if (summary == null) {
        emit(const SummaryError('No summary available for this recording'));
      } else {
        emit(SummaryLoaded(summary));
      }
    });
  }

  void _onResummarizeRecording(
    ResummarizeRecordingEvent event,
    Emitter<SummaryState> emit,
  ) async {
    emit(SummaryLoading());

    try {
      // Generate new summary
      await summaryRemoteDataSource.generateSummary(event.recordingId);

      // Wait a bit for the summary to be generated
      await Future.delayed(const Duration(seconds: 2));

      // Reload the summary
      final result = await getLatestSummaryForRecording(event.recordingId);

      result.fold((failure) => emit(SummaryError(failure.message)), (summary) {
        if (summary == null) {
          emit(
            const SummaryError(
              'Summary generation in progress. Please try again in a moment.',
            ),
          );
        } else {
          emit(SummaryLoaded(summary));
          // Invalidate cache by clearing cached data and reloading summaries list
          _cachedSummariesList = null;
          _cachedAllSummariesList = null;
          add(const LoadSummariesListEvent());
        }
      });
    } catch (e) {
      emit(SummaryError('Failed to re-summarize: $e'));
    }
  }

  void _onSaveRecordingToFolder(
    SaveRecordingToFolderEvent event,
    Emitter<SummaryState> emit,
  ) async {
    // Try to extract summary from current state (check multiple state types)
    Summary? currentSavingSummary;

    if (state is SummaryLoaded) {
      currentSavingSummary = (state as SummaryLoaded).summary;
    } else if (state is SummarySaving) {
      currentSavingSummary = (state as SummarySaving).summary;
    } else if (state is RecordingSaved) {
      currentSavingSummary = (state as RecordingSaved).summary;
    }

    // If summary not found in current state, fetch it from repository as fallback
    Summary summaryToSave;
    if (currentSavingSummary == null) {
      final summaryResult = await getLatestSummaryForRecording(
        event.recordingId,
      );
      final fetchedSummary = await summaryResult.fold<Summary?>((failure) {
        emit(SummaryError('Summary not loaded: ${failure.message}'));
        return null;
      }, (summary) => summary);

      // If we still don't have a summary, return early
      if (fetchedSummary == null) {
        return;
      }

      summaryToSave = fetchedSummary;
    } else {
      summaryToSave = currentSavingSummary;
    }

    // Emit saving state
    emit(SummarySaving(summaryToSave));

    final result = await recordingRepository.updateRecording(
      recordingId: event.recordingId,
      folderId: event.folderId,
    );

    // Handle result - extract value first, then do async work
    final failureOrRecording = result.fold<dynamic>(
      (failure) => failure,
      (recording) => recording,
    );

    // Check if it's a failure or success
    if (failureOrRecording is Failure) {
      // Emit error but keep current summary loaded
      emit(
        SummaryError('Failed to save to folder: ${failureOrRecording.message}'),
      );
      // Restore summary loaded state
      emit(SummaryLoaded(summaryToSave));
      return;
    }

    // Success case - do async work to get folder name
    String? folderName;
    if (event.folderId != null) {
      final foldersResult = await folderRepository.getFolders();
      foldersResult.fold((failure) => null, (folders) {
        try {
          final folder = folders.firstWhere(
            (f) => f.folderId == event.folderId,
          );
          folderName = folder.name;
        } catch (e) {
          // Folder not found, use null (will show generic message)
          folderName = null;
        }
      });
    } else {
      folderName = 'Root level';
    }

    // Success - emit RecordingSaved state with current summary and folder name
    emit(RecordingSaved(summaryToSave, folderName: folderName));

    _cachedSummariesList = null;
    _cachedAllSummariesList = null;
    _cachedFolders = null;
    add(const LoadSummariesListEvent(forceRefresh: true));
    add(const LoadFoldersEvent());
  }

  void _onLoadFolders(
    LoadFoldersEvent event,
    Emitter<SummaryState> emit,
  ) async {
    // Return early if data is already cached (check both state and cache)
    if (state is FoldersLoaded) {
      _cachedFolders = (state as FoldersLoaded).folders;
      return; // Keep current cached state
    }
    if (_cachedFolders != null) {
      if (_cachedSummariesList != null) {
        emit(_cachedSummariesList!);
        return;
      }
      emit(FoldersLoaded(_cachedFolders!));
      return; // Use cached data
    }

    emit(FoldersLoading());

    final result = await folderRepository.getFolders();

    result.fold(
      (failure) =>
          emit(SummaryError('Failed to load folders: ${failure.message}')),
      (folders) {
        _cachedFolders = folders; // Cache the data

        // If summaries are cached, we need to UPDATE the cached summaries list with new folders
        if (_cachedSummariesList != null) {
          final currentSummaries = _cachedSummariesList!;

          final updatedState = SummariesListLoaded(
            summaries: currentSummaries.summaries,
            recordingsMap: currentSummaries.recordingsMap,
            foldersMap: currentSummaries.foldersMap,
            folders: folders, // Update with fresh folders
          );

          _cachedSummariesList = updatedState;

          // Emit the updated state
          emit(updatedState);
          return;
        }

        emit(FoldersLoaded(folders));
      },
    );
  }

  void _onLoadSummariesList(
    LoadSummariesListEvent event,
    Emitter<SummaryState> emit,
  ) async {
    // If force refresh is requested, clear cache
    if (event.forceRefresh) {
      _cachedSummariesList = null;
      _cachedFolders = null;
      if (event.folderId == null) {
        _cachedAllSummariesList = null;
      }
    }

    if (event.folderId == null && !event.forceRefresh) {
      if (_cachedAllSummariesList != null) {
        emit(_cachedAllSummariesList!);
        return;
      }
    }

    if (!event.forceRefresh && state is SummariesListLoaded) {}

    if (!event.forceRefresh &&
        _cachedSummariesList != null &&
        event.folderId != null) {}

    emit(SummariesListLoading());

    try {
      // Step 1: Fetch all recordings
      final recordingsResult = await recordingRepository.getRecordings(
        isTrashed: false,
        folderId: event.folderId,
      );

      final recordings = await recordingsResult.fold(
        (failure) => <Recording>[],
        (recordings) => recordings,
      );

      final foldersResult = await folderRepository.getFolders();
      final folders = await foldersResult.fold(
        (failure) => <Folder>[],
        (folders) => folders,
      );

      final foldersMapById = <String, Folder>{};
      for (final folder in folders) {
        foldersMapById[folder.folderId] = folder;
      }

      // If recordings are empty, return early but WITH folders
      if (recordings.isEmpty) {
        final emptyState = SummariesListLoaded(
          summaries: const [],
          recordingsMap: const {},
          foldersMap: const {},
          folders: folders, // Use fetched folders
        );
        _cachedSummariesList = emptyState;
        if (event.folderId == null) {
          _cachedAllSummariesList = emptyState;
        }
        emit(emptyState);
        return;
      }

      final summaries = <Summary>[];
      final recordingsMap = <String, Recording>{};
      final foldersMap = <String, Folder?>{};

      for (final recording in recordings) {
        recordingsMap[recording.recordingId] = recording;

        // Get folder for this recording
        if (recording.folderId != null) {
          foldersMap[recording.recordingId] =
              foldersMapById[recording.folderId];
        } else {
          foldersMap[recording.recordingId] = null;
        }

        // Fetch latest summary for this recording
        final summaryResult = await summaryRepository.getSummaries(
          recordingId: recording.recordingId,
          latest: true,
        );

        summaryResult.fold(
          (failure) {
            // No summary for this recording, skip
          },
          (summaryList) {
            if (summaryList.isNotEmpty) {
              summaries.add(summaryList.first);
            }
          },
        );
      }

      final loadedState = SummariesListLoaded(
        summaries: summaries,
        recordingsMap: recordingsMap,
        foldersMap: foldersMap,
        folders: folders,
      );
      _cachedSummariesList = loadedState; // Cache as "current"
      if (event.folderId == null) {
        _cachedAllSummariesList = loadedState; // Cache as "all"
      }
      emit(loadedState);
    } catch (e) {
      emit(SummaryError('Failed to load summaries list: $e'));
    }
  }

  void _onFolderChosen(FolderChosenEvent event, Emitter<SummaryState> emit) {
    // Trigger save flow
    add(
      SaveRecordingToFolderEvent(
        recordingId: event.recordingId,
        folderId: event.folderId,
      ),
    );
  }

  void _onCreateFolderRequested(
    CreateFolderRequestedEvent event,
    Emitter<SummaryState> emit,
  ) {}

  void _onFolderCreated(FolderCreatedEvent event, Emitter<SummaryState> emit) {
    // Auto-select the newly created folder and save
    add(
      FolderChosenEvent(
        recordingId: event.recordingId,
        folderId: event.folderId,
      ),
    );
  }

  void _onUpdateFolder(
    UpdateFolderEvent event,
    Emitter<SummaryState> emit,
  ) async {
    // Optimistic Update
    final curState = state;
    if (curState is SummariesListLoaded) {
      final updatedFolders =
          curState.folders.map((f) {
            if (f.folderId == event.folderId) {
              return Folder(
                folderId: f.folderId,
                name: event.name,
                userId: f.userId,
                createdAt: f.createdAt,
                isDeleted: false,
              );
            }
            return f;
          }).toList();

      final newState = SummariesListLoaded(
        summaries: curState.summaries,
        recordingsMap: curState.recordingsMap,
        foldersMap:
            curState.foldersMap, // Ideally update this too if mapped by ID
        folders: updatedFolders,
      );

      _cachedSummariesList = newState;
      _cachedFolders = updatedFolders;
      emit(newState);
    }

    final result = await folderRepository.updateFolder(
      folderId: event.folderId,
      name: event.name,
    );

    result.fold(
      (failure) {
        emit(SummaryError(failure.message));
        add(
          LoadSummariesListEvent(folderId: event.folderId, forceRefresh: true),
        );
      },
      (folder) {
        // Confirmed success, state already updated optimistically
      },
    );
  }

  void _onDeleteFolder(
    DeleteFolderEvent event,
    Emitter<SummaryState> emit,
  ) async {
    // Optimistic Update
    final curState = state;
    if (curState is SummariesListLoaded) {
      final updatedFolders =
          curState.folders.where((f) => f.folderId != event.folderId).toList();

      final newState = SummariesListLoaded(
        summaries: curState.summaries,
        recordingsMap: curState.recordingsMap,
        foldersMap: curState.foldersMap,
        folders: updatedFolders,
      );

      _cachedSummariesList = newState;
      _cachedFolders = updatedFolders;
      emit(newState);
    }

    final result = await folderRepository.deleteFolder(event.folderId);

    result.fold(
      (failure) {
        emit(SummaryError(failure.message));
        add(const LoadSummariesListEvent(forceRefresh: true));
      },
      (_) {
        // Success
      },
    );
  }

  void _onUpdateRecording(
    UpdateRecordingEvent event,
    Emitter<SummaryState> emit,
  ) async {
    // Optimistic update
    final curState = state;
    if (curState is SummariesListLoaded) {
      final updatedRecording = curState.recordingsMap[event.recordingId]!
          .copyWith(
            title: event.title,
            folderId: event.folderId,
            isPinned: event.isPinned,
          );

      final newRecordingsMap = Map<String, Recording>.from(
        curState.recordingsMap,
      );
      newRecordingsMap[event.recordingId] = updatedRecording;

      // Update folders map if folder changed
      final newFoldersMap = Map<String, Folder?>.from(curState.foldersMap);
      if (event.folderId != null) {
        // If we have folders loaded, we can try to find it
        // Ideally we look up in curState.folders
        Folder? newFolder;
        try {
          newFolder = curState.folders.firstWhere(
            (f) => f.folderId == event.folderId,
          );
        } catch (_) {}
        newFoldersMap[event.recordingId] = newFolder;
      } else {
        newFoldersMap[event.recordingId] = null;
      }

      final newState = SummariesListLoaded(
        summaries: curState.summaries,
        recordingsMap: newRecordingsMap,
        foldersMap: newFoldersMap,
        folders: curState.folders,
      );

      _cachedSummariesList = newState;
      // Update global cache
      if (_cachedAllSummariesList != null) {
        final allCur = _cachedAllSummariesList!;
        final newRecordingsMapAll = Map<String, Recording>.from(
          allCur.recordingsMap,
        );
        newRecordingsMapAll[event.recordingId] = updatedRecording;

        _cachedAllSummariesList = SummariesListLoaded(
          summaries: allCur.summaries,
          recordingsMap: newRecordingsMapAll,
          foldersMap: allCur.foldersMap,
          folders: allCur.folders,
        );
      }
      emit(newState);
    } else {
      emit(SummaryLoading());
    }

    final result = await recordingRepository.updateRecording(
      recordingId: event.recordingId,
      title: event.title,
      folderId: event.folderId,
      isPinned: event.isPinned,
    );

    result.fold(
      (failure) {
        emit(SummaryError(failure.message));
        add(
          const LoadSummariesListEvent(forceRefresh: true),
        ); // Revert on failure
      },
      (recording) {
        // Build new state to confirm update (or rely on optimistic)
        // If not optimistic, we would reload. But optimistic is better.
        if (state is! SummariesListLoaded) {
          add(const LoadSummariesListEvent(forceRefresh: true));
        }
      },
    );
  }

  void _onDeleteRecording(
    DeleteRecordingEvent event,
    Emitter<SummaryState> emit,
  ) async {
    // Optimistic update
    final curState = state;
    if (curState is SummariesListLoaded) {
      final newSummaries =
          curState.summaries
              .where((s) => s.recordingId != event.recordingId)
              .toList();
      final newRecordingsMap = Map<String, Recording>.from(
        curState.recordingsMap,
      );
      newRecordingsMap.remove(event.recordingId);
      final newFoldersMap = Map<String, Folder?>.from(curState.foldersMap);
      newFoldersMap.remove(event.recordingId);

      final newState = SummariesListLoaded(
        summaries: newSummaries,
        recordingsMap: newRecordingsMap,
        foldersMap: newFoldersMap,
        folders: curState.folders,
      );

      _cachedSummariesList = newState;
      // Update global cache
      if (_cachedAllSummariesList != null) {
        final allCur = _cachedAllSummariesList!;
        final newSummariesAll =
            allCur.summaries
                .where((s) => s.recordingId != event.recordingId)
                .toList();
        final newRecordingsMapAll = Map<String, Recording>.from(
          allCur.recordingsMap,
        );
        newRecordingsMapAll.remove(event.recordingId);

        _cachedAllSummariesList = SummariesListLoaded(
          summaries: newSummariesAll,
          recordingsMap: newRecordingsMapAll,
          foldersMap: allCur.foldersMap,
          folders: allCur.folders,
        );
      }
      emit(newState);
    } else {
      emit(SummaryLoading());
    }

    final result = await recordingRepository.softDeleteRecording(
      event.recordingId,
    );

    result.fold(
      (failure) {
        emit(SummaryError(failure.message));
        add(const LoadSummariesListEvent(forceRefresh: true));
      },
      (_) {
        if (state is! SummariesListLoaded) {
          add(const LoadSummariesListEvent(forceRefresh: true));
        }
      },
    );
  }

  void _onLoadTrashedRecordings(
    LoadTrashedRecordingsEvent event,
    Emitter<SummaryState> emit,
  ) async {
    // Check cache
    if (!event.forceRefresh && _cachedTrashedRecordings != null) {
      emit(TrashedRecordingsLoaded(_cachedTrashedRecordings!));
      return;
    }

    emit(SummaryLoading());
    final result = await recordingRepository.getRecordings(isTrashed: true);
    result.fold((failure) => emit(SummaryError(failure.message)), (recordings) {
      _cachedTrashedRecordings = recordings;
      emit(TrashedRecordingsLoaded(recordings));
    });
  }

  void _onRestoreRecording(
    RestoreRecordingEvent event,
    Emitter<SummaryState> emit,
  ) async {
    emit(SummaryLoading());
    final result = await recordingRepository.restoreRecording(
      event.recordingId,
    );
    result.fold((failure) => emit(SummaryError(failure.message)), (recording) {
      emit(RecordingRestored(recording));
      // Reload trash list
      add(const LoadTrashedRecordingsEvent(forceRefresh: true));
      // Invalidate main list cache
      _cachedSummariesList = null;
      _cachedAllSummariesList = null;
    });
  }

  void _onHardDeleteRecording(
    HardDeleteRecordingEvent event,
    Emitter<SummaryState> emit,
  ) async {
    emit(SummaryLoading());
    final result = await recordingRepository.hardDeleteRecording(
      event.recordingId,
    );
    result.fold((failure) => emit(SummaryError(failure.message)), (_) {
      emit(const RecordingHardDeleted());
      add(const LoadTrashedRecordingsEvent(forceRefresh: true));
    });
  }
}
