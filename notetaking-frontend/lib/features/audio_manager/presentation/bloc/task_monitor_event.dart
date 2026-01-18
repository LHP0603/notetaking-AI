import 'package:equatable/equatable.dart';

abstract class TaskMonitorEvent extends Equatable {
  const TaskMonitorEvent();

  @override
  List<Object?> get props => [];
}

class StartTaskMonitoring extends TaskMonitorEvent {
  const StartTaskMonitoring();
}

class StopTaskMonitoring extends TaskMonitorEvent {
  const StopTaskMonitoring();
}

class RefreshUploadTasks extends TaskMonitorEvent {
  const RefreshUploadTasks();
}

class RefreshTranscribeTasks extends TaskMonitorEvent {
  const RefreshTranscribeTasks();
}

class RefreshSummarizeTasks extends TaskMonitorEvent {
  const RefreshSummarizeTasks();
}
