import 'package:equatable/equatable.dart';
import '../../../folder/domain/entities/folder.dart';
import '../../domain/entities/recording.dart';

abstract class RecordingsListState extends Equatable {
  const RecordingsListState();

  @override
  List<Object?> get props => [];
}

class RecordingsListInitial extends RecordingsListState {}

class RecordingsListLoading extends RecordingsListState {}

class RecordingsListLoaded extends RecordingsListState {
  final List<Folder> folders;
  final String? selectedFolderId;
  final String searchText;
  final List<Recording> recordings;
  final int currentPage;
  final bool hasMore;
  final bool isLoadingMore;

  const RecordingsListLoaded({
    required this.folders,
    this.selectedFolderId,
    this.searchText = '',
    required this.recordings,
    this.currentPage = 1,
    this.hasMore = true,
    this.isLoadingMore = false,
  });

  RecordingsListLoaded copyWith({
    List<Folder>? folders,
    String? selectedFolderId,
    String? searchText,
    List<Recording>? recordings,
    int? currentPage,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return RecordingsListLoaded(
      folders: folders ?? this.folders,
      selectedFolderId: selectedFolderId ?? this.selectedFolderId,
      searchText: searchText ?? this.searchText,
      recordings: recordings ?? this.recordings,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props => [
    folders,
    selectedFolderId,
    searchText,
    recordings,
    currentPage,
    hasMore,
    isLoadingMore,
  ];
}

class RecordingsListError extends RecordingsListState {
  final String message;
  final List<Folder>? folders;
  final List<Recording>? recordings;

  const RecordingsListError({
    required this.message,
    this.folders,
    this.recordings,
  });

  @override
  List<Object?> get props => [message, folders, recordings];
}
