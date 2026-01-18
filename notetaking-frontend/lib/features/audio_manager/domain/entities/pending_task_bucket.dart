import 'package:equatable/equatable.dart';
import 'pending_task.dart';

class PendingTaskBucket extends Equatable {
  final List<PendingTask> untranscribedAudios;
  final List<PendingTask> unsummarizedTranscripts;

  const PendingTaskBucket({
    required this.untranscribedAudios,
    required this.unsummarizedTranscripts,
  });

  @override
  List<Object?> get props => [untranscribedAudios, unsummarizedTranscripts];
}
