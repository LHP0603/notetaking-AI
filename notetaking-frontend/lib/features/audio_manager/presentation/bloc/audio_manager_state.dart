import 'package:equatable/equatable.dart';
import '../../domain/entities/audio_file.dart';
import '../../domain/entities/pending_task.dart';
import '../../domain/entities/server_task.dart';
import 'pending_audio_type.dart';

class AudioManagerState extends Equatable {
  final List<AudioFile> audios;
  final int totalCount;
  final List<ServerTask> uploadingTasks;
  final List<ServerTask> transcribingTasks;
  final List<ServerTask> summarizingTasks;
  final List<PendingTask> untranscribedAudios;
  final List<PendingTask> unsummarizedTranscripts;
  final List<AudioFile> pendingUntranscribedAudios;
  final List<AudioFile> pendingUnsummarizedAudios;
  final int pendingUntranscribedCount;
  final int pendingUnsummarizedCount;
  final List<AudioFile> pendingDetailAudios;
  final PendingAudioType? pendingDetailType;
  final int pendingDetailPage;
  final bool pendingDetailHasMore;
  final bool isLoadingAudios;
  final bool isLoadingTasks;
  final bool isLoadingPending;
  final bool isLoadingPendingAudios;
  final bool isLoadingMore;
  final bool pendingDetailIsLoading;
  final bool pendingDetailIsLoadingMore;
  final bool isUploading;
  final double uploadProgress;
  final String? errorMessage;
  final String? successMessage;
  final String? pendingErrorMessage;
  final String searchQuery;
  final DateTime? fromDate;
  final DateTime? toDate;
  final String pendingDetailSearchQuery;
  final DateTime? pendingDetailFromDate;
  final DateTime? pendingDetailToDate;
  final int page;
  final int limit;
  final bool hasMoreAudios;

  const AudioManagerState({
    required this.audios,
    required this.totalCount,
    required this.uploadingTasks,
    required this.transcribingTasks,
    required this.summarizingTasks,
    required this.untranscribedAudios,
    required this.unsummarizedTranscripts,
    required this.pendingUntranscribedAudios,
    required this.pendingUnsummarizedAudios,
    required this.pendingUntranscribedCount,
    required this.pendingUnsummarizedCount,
    required this.pendingDetailAudios,
    required this.pendingDetailType,
    required this.pendingDetailPage,
    required this.pendingDetailHasMore,
    required this.isLoadingAudios,
    required this.isLoadingTasks,
    required this.isLoadingPending,
    required this.isLoadingPendingAudios,
    required this.isLoadingMore,
    required this.pendingDetailIsLoading,
    required this.pendingDetailIsLoadingMore,
    required this.isUploading,
    required this.uploadProgress,
    required this.errorMessage,
    required this.successMessage,
    required this.pendingErrorMessage,
    required this.searchQuery,
    required this.fromDate,
    required this.toDate,
    required this.pendingDetailSearchQuery,
    required this.pendingDetailFromDate,
    required this.pendingDetailToDate,
    required this.page,
    required this.limit,
    required this.hasMoreAudios,
  });

  factory AudioManagerState.initial() {
    return const AudioManagerState(
      audios: [],
      totalCount: 0,
      uploadingTasks: [],
      transcribingTasks: [],
      summarizingTasks: [],
      untranscribedAudios: [],
      unsummarizedTranscripts: [],
      pendingUntranscribedAudios: [],
      pendingUnsummarizedAudios: [],
      pendingUntranscribedCount: 0,
      pendingUnsummarizedCount: 0,
      pendingDetailAudios: [],
      pendingDetailType: null,
      pendingDetailPage: 1,
      pendingDetailHasMore: true,
      isLoadingAudios: false,
      isLoadingTasks: false,
      isLoadingPending: false,
      isLoadingPendingAudios: false,
      isLoadingMore: false,
      pendingDetailIsLoading: false,
      pendingDetailIsLoadingMore: false,
      isUploading: false,
      uploadProgress: 0,
      errorMessage: null,
      successMessage: null,
      pendingErrorMessage: null,
      searchQuery: '',
      fromDate: null,
      toDate: null,
      pendingDetailSearchQuery: '',
      pendingDetailFromDate: null,
      pendingDetailToDate: null,
      page: 1,
      limit: 10,
      hasMoreAudios: true,
    );
  }

  AudioManagerState copyWith({
    List<AudioFile>? audios,
    int? totalCount,
    List<ServerTask>? uploadingTasks,
    List<ServerTask>? transcribingTasks,
    List<ServerTask>? summarizingTasks,
    List<PendingTask>? untranscribedAudios,
    List<PendingTask>? unsummarizedTranscripts,
    List<AudioFile>? pendingUntranscribedAudios,
    List<AudioFile>? pendingUnsummarizedAudios,
    int? pendingUntranscribedCount,
    int? pendingUnsummarizedCount,
    List<AudioFile>? pendingDetailAudios,
    PendingAudioType? pendingDetailType,
    int? pendingDetailPage,
    bool? pendingDetailHasMore,
    bool? isLoadingAudios,
    bool? isLoadingTasks,
    bool? isLoadingPending,
    bool? isLoadingPendingAudios,
    bool? isLoadingMore,
    bool? pendingDetailIsLoading,
    bool? pendingDetailIsLoadingMore,
    bool? isUploading,
    double? uploadProgress,
    String? errorMessage,
    String? successMessage,
    String? pendingErrorMessage,
    String? searchQuery,
    DateTime? fromDate,
    DateTime? toDate,
    String? pendingDetailSearchQuery,
    DateTime? pendingDetailFromDate,
    DateTime? pendingDetailToDate,
    int? page,
    int? limit,
    bool? hasMoreAudios,
  }) {
    return AudioManagerState(
      audios: audios ?? this.audios,
      totalCount: totalCount ?? this.totalCount,
      uploadingTasks: uploadingTasks ?? this.uploadingTasks,
      transcribingTasks: transcribingTasks ?? this.transcribingTasks,
      summarizingTasks: summarizingTasks ?? this.summarizingTasks,
      untranscribedAudios: untranscribedAudios ?? this.untranscribedAudios,
      unsummarizedTranscripts:
          unsummarizedTranscripts ?? this.unsummarizedTranscripts,
      pendingUntranscribedAudios:
          pendingUntranscribedAudios ?? this.pendingUntranscribedAudios,
      pendingUnsummarizedAudios:
          pendingUnsummarizedAudios ?? this.pendingUnsummarizedAudios,
      pendingUntranscribedCount:
          pendingUntranscribedCount ?? this.pendingUntranscribedCount,
      pendingUnsummarizedCount:
          pendingUnsummarizedCount ?? this.pendingUnsummarizedCount,
      pendingDetailAudios: pendingDetailAudios ?? this.pendingDetailAudios,
      pendingDetailType: pendingDetailType ?? this.pendingDetailType,
      pendingDetailPage: pendingDetailPage ?? this.pendingDetailPage,
      pendingDetailHasMore: pendingDetailHasMore ?? this.pendingDetailHasMore,
      isLoadingAudios: isLoadingAudios ?? this.isLoadingAudios,
      isLoadingTasks: isLoadingTasks ?? this.isLoadingTasks,
      isLoadingPending: isLoadingPending ?? this.isLoadingPending,
      isLoadingPendingAudios:
          isLoadingPendingAudios ?? this.isLoadingPendingAudios,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      pendingDetailIsLoading:
          pendingDetailIsLoading ?? this.pendingDetailIsLoading,
      pendingDetailIsLoadingMore:
          pendingDetailIsLoadingMore ?? this.pendingDetailIsLoadingMore,
      isUploading: isUploading ?? this.isUploading,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      errorMessage: errorMessage,
      successMessage: successMessage,
      pendingErrorMessage: pendingErrorMessage,
      searchQuery: searchQuery ?? this.searchQuery,
      fromDate: fromDate ?? this.fromDate,
      toDate: toDate ?? this.toDate,
      pendingDetailSearchQuery:
          pendingDetailSearchQuery ?? this.pendingDetailSearchQuery,
      pendingDetailFromDate:
          pendingDetailFromDate ?? this.pendingDetailFromDate,
      pendingDetailToDate: pendingDetailToDate ?? this.pendingDetailToDate,
      page: page ?? this.page,
      limit: limit ?? this.limit,
      hasMoreAudios: hasMoreAudios ?? this.hasMoreAudios,
    );
  }

  @override
  List<Object?> get props => [
    audios,
    totalCount,
    uploadingTasks,
    transcribingTasks,
    summarizingTasks,
    untranscribedAudios,
    unsummarizedTranscripts,
    pendingUntranscribedAudios,
    pendingUnsummarizedAudios,
    pendingUntranscribedCount,
    pendingUnsummarizedCount,
    pendingDetailAudios,
    pendingDetailType,
    pendingDetailPage,
    pendingDetailHasMore,
    isLoadingAudios,
    isLoadingTasks,
    isLoadingPending,
    isLoadingPendingAudios,
    isLoadingMore,
    pendingDetailIsLoading,
    pendingDetailIsLoadingMore,
    isUploading,
    uploadProgress,
    errorMessage,
    successMessage,
    pendingErrorMessage,
    searchQuery,
    fromDate,
    toDate,
    pendingDetailSearchQuery,
    pendingDetailFromDate,
    pendingDetailToDate,
    page,
    limit,
    hasMoreAudios,
  ];
}
