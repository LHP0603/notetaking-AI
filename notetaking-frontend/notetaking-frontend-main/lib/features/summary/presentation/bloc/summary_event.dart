import 'package:equatable/equatable.dart';
import '../../domain/entities/summary.dart';

abstract class SummaryEvent extends Equatable {
  const SummaryEvent();

  @override
  List<Object?> get props => [];
}

class GetSummaryEvent extends SummaryEvent {
  final String transcriptionId;

  const GetSummaryEvent(this.transcriptionId);

  @override
  List<Object> get props => [transcriptionId];
}

class SaveSummaryEvent extends SummaryEvent {
  final Summary summary;

  const SaveSummaryEvent(this.summary);

  @override
  List<Object> get props => [summary];
}

class ResummarizeEvent extends SummaryEvent {
  final String transcriptionId;

  const ResummarizeEvent(this.transcriptionId);

  @override
  List<Object> get props => [transcriptionId];
}

class UpdateActionItemEvent extends SummaryEvent {
  final String summaryId;
  final String actionItemId;
  final bool isCompleted;

  const UpdateActionItemEvent({
    required this.summaryId,
    required this.actionItemId,
    required this.isCompleted,
  });

  @override
  List<Object> get props => [summaryId, actionItemId, isCompleted];
}

class ResetSummaryEvent extends SummaryEvent {}

class LoadSummaryForRecordingEvent extends SummaryEvent {
  final String recordingId;

  const LoadSummaryForRecordingEvent(this.recordingId);

  @override
  List<Object> get props => [recordingId];
}

class ResummarizeRecordingEvent extends SummaryEvent {
  final String recordingId;

  const ResummarizeRecordingEvent(this.recordingId);

  @override
  List<Object> get props => [recordingId];
}

class ExportRecordingEvent extends SummaryEvent {
  final String recordingId;
  final String exportType;

  const ExportRecordingEvent({
    required this.recordingId,
    required this.exportType,
  });

  @override
  List<Object?> get props => [recordingId, exportType];
}

class SaveRecordingToFolderEvent extends SummaryEvent {
  final String recordingId;
  final String? folderId;

  const SaveRecordingToFolderEvent({required this.recordingId, this.folderId});

  @override
  List<Object?> get props => [recordingId, folderId];
}

class LoadFoldersEvent extends SummaryEvent {
  const LoadFoldersEvent();
}

class LoadSummariesListEvent extends SummaryEvent {
  final String? folderId;
  final bool forceRefresh;

  const LoadSummariesListEvent({this.folderId, this.forceRefresh = false});

  @override
  List<Object?> get props => [folderId, forceRefresh];
}

class FolderChosenEvent extends SummaryEvent {
  final String recordingId;
  final String? folderId;

  const FolderChosenEvent({required this.recordingId, this.folderId});

  @override
  List<Object?> get props => [recordingId, folderId];
}

class CreateFolderRequestedEvent extends SummaryEvent {
  const CreateFolderRequestedEvent();
}

class FolderCreatedEvent extends SummaryEvent {
  final String folderId;
  final String recordingId;

  const FolderCreatedEvent({required this.folderId, required this.recordingId});

  @override
  List<Object> get props => [folderId, recordingId];
}

class UpdateFolderEvent extends SummaryEvent {
  final String folderId;
  final String name;

  const UpdateFolderEvent({required this.folderId, required this.name});

  @override
  List<Object> get props => [folderId, name];
}

class DeleteFolderEvent extends SummaryEvent {
  final String folderId;

  const DeleteFolderEvent(this.folderId);

  @override
  List<Object> get props => [folderId];
}

class UpdateRecordingEvent extends SummaryEvent {
  final String recordingId;
  final String? title;
  final String? folderId;
  final bool? isPinned;

  const UpdateRecordingEvent({
    required this.recordingId,
    this.title,
    this.folderId,
    this.isPinned,
  });

  @override
  List<Object?> get props => [recordingId, title, folderId, isPinned];
}

class DeleteRecordingEvent extends SummaryEvent {
  final String recordingId;

  const DeleteRecordingEvent(this.recordingId);

  @override
  List<Object> get props => [recordingId];
}

class LoadTrashedRecordingsEvent extends SummaryEvent {
  final bool forceRefresh;

  const LoadTrashedRecordingsEvent({this.forceRefresh = false});

  @override
  List<Object?> get props => [forceRefresh];
}

class RestoreRecordingEvent extends SummaryEvent {
  final String recordingId;

  const RestoreRecordingEvent(this.recordingId);

  @override
  List<Object> get props => [recordingId];
}

class HardDeleteRecordingEvent extends SummaryEvent {
  final String recordingId;

  const HardDeleteRecordingEvent(this.recordingId);

  @override
  List<Object> get props => [recordingId];
}
