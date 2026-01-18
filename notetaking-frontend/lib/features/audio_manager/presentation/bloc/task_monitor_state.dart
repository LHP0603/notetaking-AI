import 'package:equatable/equatable.dart';
import '../../domain/entities/task.dart';

abstract class TaskMonitorState extends Equatable {
  const TaskMonitorState();

  @override
  List<Object?> get props => [];
}

class TaskMonitorInitial extends TaskMonitorState {}

class TasksLoaded extends TaskMonitorState {
  final List<Task> uploadTasks;
  final List<Task> transcribeTasks;
  final List<Task> summarizeTasks;

  const TasksLoaded({
    required this.uploadTasks,
    required this.transcribeTasks,
    required this.summarizeTasks,
  });

  TasksLoaded copyWithUploadTasks(List<Task> tasks) {
    return TasksLoaded(
      uploadTasks: tasks,
      transcribeTasks: transcribeTasks,
      summarizeTasks: summarizeTasks,
    );
  }

  TasksLoaded copyWithTranscribeTasks(List<Task> tasks) {
    return TasksLoaded(
      uploadTasks: uploadTasks,
      transcribeTasks: tasks,
      summarizeTasks: summarizeTasks,
    );
  }

  TasksLoaded copyWithSummarizeTasks(List<Task> tasks) {
    return TasksLoaded(
      uploadTasks: uploadTasks,
      transcribeTasks: transcribeTasks,
      summarizeTasks: tasks,
    );
  }

  @override
  List<Object?> get props => [uploadTasks, transcribeTasks, summarizeTasks];
}
