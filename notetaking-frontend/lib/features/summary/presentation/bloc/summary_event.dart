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

