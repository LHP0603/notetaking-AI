import 'package:equatable/equatable.dart';

abstract class RecordingsListEvent extends Equatable {
  const RecordingsListEvent();

  @override
  List<Object?> get props => [];
}

class RecordingsListStarted extends RecordingsListEvent {
  const RecordingsListStarted();
}

class FolderSelected extends RecordingsListEvent {
  final String? folderId;

  const FolderSelected(this.folderId);

  @override
  List<Object?> get props => [folderId];
}

class SearchChanged extends RecordingsListEvent {
  final String searchText;

  const SearchChanged(this.searchText);

  @override
  List<Object?> get props => [searchText];
}

class LoadMoreRecordings extends RecordingsListEvent {
  const LoadMoreRecordings();
}

class CreateFolderRequested extends RecordingsListEvent {
  final String name;
  final String? parentFolderId;

  const CreateFolderRequested({
    required this.name,
    this.parentFolderId,
  });

  @override
  List<Object?> get props => [name, parentFolderId];
}

class RefreshRecordings extends RecordingsListEvent {
  const RefreshRecordings();
}


