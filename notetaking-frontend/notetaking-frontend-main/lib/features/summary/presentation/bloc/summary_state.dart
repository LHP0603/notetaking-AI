import 'package:equatable/equatable.dart';
import '../../domain/entities/summary.dart';
import '../../../folder/domain/entities/folder.dart';
import '../../../recording/domain/entities/recording.dart';

abstract class SummaryState extends Equatable {
  const SummaryState();

  @override
  List<Object?> get props => [];
}

class SummaryInitial extends SummaryState {}

class SummaryLoading extends SummaryState {}

class SummaryLoaded extends SummaryState {
  final Summary summary;

  const SummaryLoaded(this.summary);

  @override
  List<Object> get props => [summary];
}

class SummarySaved extends SummaryState {
  final Summary summary;

  const SummarySaved(this.summary);

  @override
  List<Object> get props => [summary];
}

class SummaryError extends SummaryState {
  final String message;

  const SummaryError(this.message);

  @override
  List<Object> get props => [message];
}

class RecordingSaved extends SummaryState {
  final Summary summary;
  final String? folderName; // Folder name for success message

  const RecordingSaved(this.summary, {this.folderName});

  @override
  List<Object?> get props => [summary, folderName];
}

class FoldersLoading extends SummaryState {}

class FoldersLoaded extends SummaryState {
  final List<Folder> folders;
  const FoldersLoaded(this.folders);

  @override
  List<Object> get props => [folders];
}

class SummariesListLoading extends SummaryState {}

class SummariesListLoaded extends SummaryState {
  final List<Summary> summaries;
  final Map<String, Recording> recordingsMap; // recordingId -> Recording
  final Map<String, Folder?>
  foldersMap; // recordingId -> Folder (null if no folder)
  final List<Folder> folders;

  const SummariesListLoaded({
    required this.summaries,
    required this.recordingsMap,
    required this.foldersMap,
    this.folders = const [],
  });

  @override
  List<Object> get props => [summaries, recordingsMap, foldersMap, folders];
}

class SummarySaving extends SummaryState {
  final Summary summary; // Keep current summary visible
  const SummarySaving(this.summary);

  @override
  List<Object> get props => [summary];
}

class ExportingSummary extends SummaryState {
  final Summary summary;
  const ExportingSummary(this.summary);
  @override
  List<Object> get props => [summary];
}

class ExportSuccess extends SummaryState {
  final Summary summary;
  final String downloadUrl;
  final String? message; // Optional message for success

  const ExportSuccess(this.summary, this.downloadUrl, {this.message});

  @override
  List<Object?> get props => [summary, downloadUrl, message];
}

class TrashedRecordingsLoaded extends SummaryState {
  final List<Recording> recordings;

  const TrashedRecordingsLoaded(this.recordings);

  @override
  List<Object> get props => [recordings];
}

class RecordingRestored extends SummaryState {
  final Recording recording;

  const RecordingRestored(this.recording);

  @override
  List<Object> get props => [recording];
}

class RecordingHardDeleted extends SummaryState {
  const RecordingHardDeleted();
}
