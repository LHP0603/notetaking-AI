import 'package:equatable/equatable.dart';
import 'server_task.dart';

class ServerTaskBucket extends Equatable {
  final List<ServerTask> uploading;
  final List<ServerTask> transcribing;
  final List<ServerTask> summarizing;

  const ServerTaskBucket({
    required this.uploading,
    required this.transcribing,
    required this.summarizing,
  });

  @override
  List<Object?> get props => [uploading, transcribing, summarizing];
}
