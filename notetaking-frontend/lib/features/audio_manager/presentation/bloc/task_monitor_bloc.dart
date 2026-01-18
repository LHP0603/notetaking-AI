import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/task_search_criteria.dart';
import '../../domain/usecases/search_tasks.dart';
import 'task_monitor_event.dart';
import 'task_monitor_state.dart';

class TaskMonitorBloc extends Bloc<TaskMonitorEvent, TaskMonitorState> {
  final SearchTasks searchTasks;

  Timer? _uploadPollingTimer;
  Timer? _transcribePollingTimer;
  Timer? _summarizePollingTimer;

  TaskMonitorBloc({required this.searchTasks})
    : super(TaskMonitorInitial()) {
    on<StartTaskMonitoring>(_onStartMonitoring);
    on<StopTaskMonitoring>(_onStopMonitoring);
    on<RefreshUploadTasks>(_onRefreshUploadTasks);
    on<RefreshTranscribeTasks>(_onRefreshTranscribeTasks);
    on<RefreshSummarizeTasks>(_onRefreshSummarizeTasks);
  }

  Future<void> _onStartMonitoring(
    StartTaskMonitoring event,
    Emitter<TaskMonitorState> emit,
  ) async {
    _stopPolling();
    _startPolling();
    add(const RefreshUploadTasks());
    add(const RefreshTranscribeTasks());
    add(const RefreshSummarizeTasks());
  }

  Future<void> _onStopMonitoring(
    StopTaskMonitoring event,
    Emitter<TaskMonitorState> emit,
  ) async {
    _stopPolling();
  }

  void _startPolling() {
    _uploadPollingTimer = Timer.periodic(
      AppConstants.taskPollingInterval,
      (_) => add(const RefreshUploadTasks()),
    );
    _transcribePollingTimer = Timer.periodic(
      AppConstants.taskPollingInterval,
      (_) => add(const RefreshTranscribeTasks()),
    );
    _summarizePollingTimer = Timer.periodic(
      AppConstants.taskPollingInterval,
      (_) => add(const RefreshSummarizeTasks()),
    );
  }

  void _stopPolling() {
    _uploadPollingTimer?.cancel();
    _uploadPollingTimer = null;
    _transcribePollingTimer?.cancel();
    _transcribePollingTimer = null;
    _summarizePollingTimer?.cancel();
    _summarizePollingTimer = null;
  }

  Future<void> _onRefreshUploadTasks(
    RefreshUploadTasks event,
    Emitter<TaskMonitorState> emit,
  ) async {
    final criteria = const TaskSearchCriteria(
      taskType: 'upload',
      activeOnly: true,
      pageSize: 100,
    );

    final result = await searchTasks(criteria);

    result.fold(
      (_) {},
      (tasks) {
        if (state is TasksLoaded) {
          emit((state as TasksLoaded).copyWithUploadTasks(tasks));
        } else {
          emit(
            TasksLoaded(
              uploadTasks: tasks,
              transcribeTasks: const [],
              summarizeTasks: const [],
            ),
          );
        }
      },
    );
  }

  Future<void> _onRefreshTranscribeTasks(
    RefreshTranscribeTasks event,
    Emitter<TaskMonitorState> emit,
  ) async {
    final criteria = const TaskSearchCriteria(
      taskType: 'transcribe',
      activeOnly: true,
      pageSize: 100,
    );

    final result = await searchTasks(criteria);

    result.fold(
      (_) {},
      (tasks) {
        if (state is TasksLoaded) {
          emit((state as TasksLoaded).copyWithTranscribeTasks(tasks));
        } else {
          emit(
            TasksLoaded(
              uploadTasks: const [],
              transcribeTasks: tasks,
              summarizeTasks: const [],
            ),
          );
        }
      },
    );
  }

  Future<void> _onRefreshSummarizeTasks(
    RefreshSummarizeTasks event,
    Emitter<TaskMonitorState> emit,
  ) async {
    final criteria = const TaskSearchCriteria(
      taskType: 'summarize',
      activeOnly: true,
      pageSize: 100,
    );

    final result = await searchTasks(criteria);

    result.fold(
      (_) {},
      (tasks) {
        if (state is TasksLoaded) {
          emit((state as TasksLoaded).copyWithSummarizeTasks(tasks));
        } else {
          emit(
            TasksLoaded(
              uploadTasks: const [],
              transcribeTasks: const [],
              summarizeTasks: tasks,
            ),
          );
        }
      },
    );
  }

  @override
  Future<void> close() {
    _stopPolling();
    return super.close();
  }
}
