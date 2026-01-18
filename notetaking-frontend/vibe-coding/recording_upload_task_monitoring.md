# Recording, Upload, and Task Monitoring Implementation Guide

## Overview

This document provides comprehensive instructions for implementing recording time limits, async audio upload functionality, and real-time task monitoring in the Audio Management screen. The implementation includes automatic navigation to task status monitoring and continuous polling for task updates.

## Table of Contents

1. [Feature Requirements](#feature-requirements)
2. [Recording Time Limit](#recording-time-limit)
3. [Async Audio Upload](#async-audio-upload)
4. [Task Monitoring](#task-monitoring)
5. [Implementation Steps](#implementation-steps)
6. [Code Examples](#code-examples)
7. [State Management](#state-management)
8. [API Specifications](#api-specifications)
9. [Navigation Flow](#navigation-flow)
10. [Polling Strategy](#polling-strategy)

---

## Feature Requirements

### 1. Recording Time Limit (2 Hours Maximum)

- Display notification when user starts recording about 2-hour limit
- Automatically stop recording after 2 hours
- Proceed to upload after auto-stop
- Show clear feedback to user

### 2. Async Audio Upload

- Upload completed recording to `audio/upload-async` endpoint
- Handle multipart form data with 'file' field
- Receive job_id for tracking upload progress
- Navigate to Task monitoring screen after successful response

### 3. Real-time Task Monitoring

- Display three task categories: Uploading, Transcribing, Summarizing
- Poll `tasks/search` endpoint for each task type
- Show real-time status updates
- Stop polling when user leaves the screen
- Handle pagination and filtering

---

## Recording Time Limit

### UI Notification

**When Recording Starts:**

Display a SnackBar or Dialog informing the user:

```dart
void _showRecordingLimitNotification(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text(
        'Recording limit: 2 hours maximum',
        style: TextStyle(fontSize: 16),
      ),
      backgroundColor: Colors.orange,
      duration: Duration(seconds: 4),
    ),
  );
}
```

### Recording Duration Logic

**Constants:**

```dart
// lib/core/constants/app_constants.dart

class AppConstants {
  // Existing constants...
  
  // Recording limits
  static const Duration maxRecordingDuration = Duration(hours: 2);
  static const int maxRecordingSeconds = 7200; // 2 hours = 7200 seconds
}
```

### Auto-Stop Implementation

**Update RecordingBloc:**

```dart
// lib/features/recording/presentation/bloc/recording_bloc.dart

class RecordingBloc extends Bloc<RecordingEvent, RecordingState> {
  final StartRecording startRecording;
  final StopRecording stopRecording;
  final UploadAudio uploadAudio;
  final ImportAudio importAudio;
  final RecordingRepository repository;

  StreamSubscription<Duration>? _durationSubscription;
  Timer? _autoStopTimer;

  RecordingBloc({
    required this.startRecording,
    required this.stopRecording,
    required this.uploadAudio,
    required this.importAudio,
    required this.repository,
  }) : super(const RecordingInitial()) {
    on<StartRecordingRequested>(_onStartRecording);
    on<StopRecordingRequested>(_onStopRecording);
    on<AutoStopRecordingTriggered>(_onAutoStopRecording);
    on<DurationUpdated>(_onDurationUpdated);
  }

  Future<void> _onStartRecording(
    StartRecordingRequested event,
    Emitter<RecordingState> emit,
  ) async {
    final result = await startRecording();

    result.fold(
      (failure) => emit(RecordingError(message: failure.message)),
      (_) {
        emit(const RecordingInProgress());
        
        // Set up auto-stop timer for 2 hours
        _autoStopTimer = Timer(
          AppConstants.maxRecordingDuration,
          () => add(const AutoStopRecordingTriggered()),
        );
        
        _durationSubscription?.cancel();
        _durationSubscription = repository.durationStream.listen((duration) {
          add(DurationUpdated(duration));
        });
      },
    );
  }

  Future<void> _onAutoStopRecording(
    AutoStopRecordingTriggered event,
    Emitter<RecordingState> emit,
  ) async {
    _durationSubscription?.cancel();
    _autoStopTimer?.cancel();

    final result = await stopRecording();

    result.fold(
      (failure) => emit(RecordingError(message: failure.message)),
      (recording) => emit(
        RecordingCompletedMaxDuration(
          recording: recording,
          message: 'Recording stopped: 2-hour limit reached',
        ),
      ),
    );
  }

  @override
  Future<void> close() {
    _durationSubscription?.cancel();
    _autoStopTimer?.cancel();
    return super.close();
  }
}
```

**Add New Event:**

```dart
// lib/features/recording/presentation/bloc/recording_event.dart

class AutoStopRecordingTriggered extends RecordingEvent {
  const AutoStopRecordingTriggered();
}
```

**Add New State:**

```dart
// lib/features/recording/presentation/bloc/recording_state.dart

class RecordingCompletedMaxDuration extends RecordingState {
  final Recording recording;
  final String message;

  const RecordingCompletedMaxDuration({
    required this.recording,
    required this.message,
  });

  @override
  List<Object?> get props => [recording, message];
}
```

### UI Integration

**Recording Page:**

```dart
// lib/features/recording/presentation/pages/recording_page.dart

BlocListener<RecordingBloc, RecordingState>(
  listener: (context, state) {
    if (state is RecordingInProgress && 
        state.duration == Duration.zero) {
      // Show limit notification when recording starts
      _showRecordingLimitNotification(context);
    } else if (state is RecordingCompletedMaxDuration) {
      // Show max duration reached message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 5),
        ),
      );
      
      // Automatically upload the recording
      _uploadRecording(context, state.recording);
    } else if (state is RecordingCompleted) {
      // Normal completion - user stopped manually
      _uploadRecording(context, state.recording);
    }
  },
  child: // ... rest of UI
)
```

---

## Async Audio Upload

### API Endpoint

**Endpoint:** `POST /audio/upload-async`

**Request:**
- Method: POST
- Content-Type: multipart/form-data
- Body: 
  - `file`: Audio file (binary)

**Response:**
```json
{
  "code": 200,
  "success": true,
  "message": "Task queued successfully. Use job_id to check status.",
  "data": {
    "job_id": "d819f3fe-f3c2-4877-9faf-59ca326ed69f",
    "task_type": "upload",
    "status": "queued"
  }
}
```

### Domain Layer

**Entity:**

```dart
// lib/features/recording/domain/entities/upload_job.dart

import 'package:equatable/equatable.dart';

class UploadJob extends Equatable {
  final String jobId;
  final String taskType;
  final String status;

  const UploadJob({
    required this.jobId,
    required this.taskType,
    required this.status,
  });

  @override
  List<Object?> get props => [jobId, taskType, status];
}
```

**Use Case:**

```dart
// lib/features/recording/domain/usecases/upload_recording_async.dart

import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/upload_job.dart';
import '../repositories/recording_repository.dart';

class UploadRecordingAsync {
  final RecordingRepository repository;

  UploadRecordingAsync(this.repository);

  Future<Either<Failure, UploadJob>> call(File audioFile) async {
    return await repository.uploadRecordingAsync(audioFile);
  }
}
```

**Repository Interface Update:**

```dart
// lib/features/recording/domain/repositories/recording_repository.dart

abstract class RecordingRepository {
  // Existing methods...
  
  /// Upload recording asynchronously and get job_id
  Future<Either<Failure, UploadJob>> uploadRecordingAsync(File audioFile);
}
```

### Data Layer

**Model:**

```dart
// lib/features/recording/data/models/upload_job_model.dart

import '../../domain/entities/upload_job.dart';

class UploadJobModel extends UploadJob {
  const UploadJobModel({
    required super.jobId,
    required super.taskType,
    required super.status,
  });

  factory UploadJobModel.fromJson(Map<String, dynamic> json) {
    return UploadJobModel(
      jobId: json['job_id'] as String,
      taskType: json['task_type'] as String,
      status: json['status'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'job_id': jobId,
      'task_type': taskType,
      'status': status,
    };
  }
}
```

**Remote Data Source:**

```dart
// lib/features/recording/data/datasources/recording_remote_data_source.dart

import 'dart:io';
import 'package:dio/dio.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/upload_job_model.dart';

abstract class RecordingRemoteDataSource {
  Future<UploadJobModel> uploadRecordingAsync(File audioFile);
}

class RecordingRemoteDataSourceImpl implements RecordingRemoteDataSource {
  final Dio dio;

  RecordingRemoteDataSourceImpl({required this.dio});

  @override
  Future<UploadJobModel> uploadRecordingAsync(File audioFile) async {
    try {
      final fileName = audioFile.path.split('/').last;
      
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          audioFile.path,
          filename: fileName,
        ),
      });

      final response = await dio.post(
        '/audio/upload-async',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          return UploadJobModel.fromJson(data['data']);
        } else {
          throw ServerException(
            message: data['message'] ?? 'Upload failed',
            code: data['code'] ?? 500,
          );
        }
      } else {
        throw ServerException(
          message: 'Upload failed',
          code: response.statusCode ?? 500,
        );
      }
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data['message'] ?? 'Network error occurred',
        code: e.response?.statusCode ?? 500,
      );
    }
  }
}
```

**Repository Implementation:**

```dart
// lib/features/recording/data/repositories/recording_repository_impl.dart

@override
Future<Either<Failure, UploadJob>> uploadRecordingAsync(File audioFile) async {
  if (!await networkInfo.isConnected) {
    return const Left(NetworkFailure('No internet connection'));
  }

  try {
    final uploadJob = await remoteDataSource.uploadRecordingAsync(audioFile);
    return Right(uploadJob);
  } on ServerException catch (e) {
    return Left(ServerFailure(e.message));
  } catch (e) {
    return Left(ServerFailure('Unexpected error occurred during upload'));
  }
}
```

### BLoC Integration

**Add Events:**

```dart
// lib/features/recording/presentation/bloc/recording_event.dart

class UploadRecordingRequested extends RecordingEvent {
  final File audioFile;

  const UploadRecordingRequested(this.audioFile);

  @override
  List<Object?> get props => [audioFile];
}
```

**Add States:**

```dart
// lib/features/recording/presentation/bloc/recording_state.dart

class RecordingUploading extends RecordingState {
  const RecordingUploading();
}

class RecordingUploadSuccess extends RecordingState {
  final UploadJob uploadJob;
  final String message;

  const RecordingUploadSuccess({
    required this.uploadJob,
    required this.message,
  });

  @override
  List<Object?> get props => [uploadJob, message];
}
```

**BLoC Handler:**

```dart
// lib/features/recording/presentation/bloc/recording_bloc.dart

Future<void> _onUploadRecording(
  UploadRecordingRequested event,
  Emitter<RecordingState> emit,
) async {
  emit(const RecordingUploading());

  final result = await uploadRecordingAsync(event.audioFile);

  result.fold(
    (failure) => emit(RecordingError(message: failure.message)),
    (uploadJob) => emit(
      RecordingUploadSuccess(
        uploadJob: uploadJob,
        message: 'Upload started. Job ID: ${uploadJob.jobId}',
      ),
    ),
  );
}
```

---

## Task Monitoring

### API Endpoint

**Endpoint:** `POST /tasks/search`

**Request Payload:**

```json
{
  "active_only": true,
  "order": "DESC",
  "page": 1,
  "page_size": 100,
  "task_type": "upload"
}
```

**Available Task Types:**
- `"upload"` - For Uploading section
- `"transcribe"` - For Transcribing section
- `"summarize"` - For Summarizing section

**Response:**

```json
{
  "code": 200,
  "success": true,
  "message": "SUCCESSFULLY",
  "data": {
    "data": [
      {
        "id": "string",
        "task_type": "string",
        "status": "string",
        "result": "string",
        "error_message": "string",
        "audio_id": 0,
        "metadata_json": {
          "filename": "recording.mp3"
        },
        "created_at": "2025-12-25T18:31:52.249Z",
        "updated_at": "2025-12-25T18:31:52.249Z"
      }
    ],
    "meta": {
      "page": 0,
      "page_size": 0,
      "item_count": 0,
      "page_count": 0,
      "has_previous_page": true,
      "has_next_page": true
    }
  }
}
```

### Domain Layer

**Entities:**

```dart
// lib/features/audio_manager/domain/entities/task.dart

import 'package:equatable/equatable.dart';

class Task extends Equatable {
  final String id;
  final String taskType;
  final String status;
  final String? result;
  final String? errorMessage;
  final int? audioId;
  final Map<String, dynamic>? metadataJson;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Task({
    required this.id,
    required this.taskType,
    required this.status,
    this.result,
    this.errorMessage,
    this.audioId,
    this.metadataJson,
    required this.createdAt,
    required this.updatedAt,
  });

  String get filename {
    return metadataJson?['filename'] ?? 'Unknown file';
  }

  bool get isActive {
    return status == 'pending' || 
           status == 'queued' || 
           status == 'processing';
  }

  bool get isCompleted {
    return status == 'completed';
  }

  bool get isFailed {
    return status == 'failed';
  }

  @override
  List<Object?> get props => [
    id,
    taskType,
    status,
    result,
    errorMessage,
    audioId,
    metadataJson,
    createdAt,
    updatedAt,
  ];
}
```

```dart
// lib/features/audio_manager/domain/entities/task_search_criteria.dart

import 'package:equatable/equatable.dart';

class TaskSearchCriteria extends Equatable {
  final bool activeOnly;
  final String order;
  final int page;
  final int pageSize;
  final String taskType;
  final DateTime? fromDate;
  final DateTime? toDate;
  final String? status;

  const TaskSearchCriteria({
    this.activeOnly = true,
    this.order = 'DESC',
    this.page = 1,
    this.pageSize = 100,
    required this.taskType,
    this.fromDate,
    this.toDate,
    this.status,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'active_only': activeOnly,
      'order': order,
      'page': page,
      'page_size': pageSize,
      'task_type': taskType,
    };

    if (fromDate != null) {
      json['from_date'] = fromDate!.toIso8601String();
    }
    if (toDate != null) {
      json['to_date'] = toDate!.toIso8601String();
    }
    if (status != null) {
      json['status'] = status;
    }

    return json;
  }

  @override
  List<Object?> get props => [
    activeOnly,
    order,
    page,
    pageSize,
    taskType,
    fromDate,
    toDate,
    status,
  ];
}
```

**Use Case:**

```dart
// lib/features/audio_manager/domain/usecases/search_tasks.dart

import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/task.dart';
import '../entities/task_search_criteria.dart';
import '../repositories/audio_manager_repository.dart';

class SearchTasks {
  final AudioManagerRepository repository;

  SearchTasks(this.repository);

  Future<Either<Failure, List<Task>>> call(
    TaskSearchCriteria criteria,
  ) async {
    return await repository.searchTasks(criteria);
  }
}
```

### Data Layer

**Models:**

```dart
// lib/features/audio_manager/data/models/task_model.dart

import '../../domain/entities/task.dart';

class TaskModel extends Task {
  const TaskModel({
    required super.id,
    required super.taskType,
    required super.status,
    super.result,
    super.errorMessage,
    super.audioId,
    super.metadataJson,
    required super.createdAt,
    required super.updatedAt,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] as String,
      taskType: json['task_type'] as String,
      status: json['status'] as String,
      result: json['result'] as String?,
      errorMessage: json['error_message'] as String?,
      audioId: json['audio_id'] as int?,
      metadataJson: json['metadata_json'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'task_type': taskType,
      'status': status,
      'result': result,
      'error_message': errorMessage,
      'audio_id': audioId,
      'metadata_json': metadataJson,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
```

**Remote Data Source:**

```dart
// lib/features/audio_manager/data/datasources/audio_manager_remote_data_source.dart

import 'package:dio/dio.dart';
import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/task_search_criteria.dart';
import '../models/task_model.dart';

abstract class AudioManagerRemoteDataSource {
  Future<List<TaskModel>> searchTasks(TaskSearchCriteria criteria);
}

class AudioManagerRemoteDataSourceImpl implements AudioManagerRemoteDataSource {
  final Dio dio;

  AudioManagerRemoteDataSourceImpl({required this.dio});

  @override
  Future<List<TaskModel>> searchTasks(TaskSearchCriteria criteria) async {
    try {
      final response = await dio.post(
        '/tasks/search',
        data: criteria.toJson(),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          final List<dynamic> tasksJson = data['data']['data'];
          return tasksJson
              .map((json) => TaskModel.fromJson(json))
              .toList();
        } else {
          throw ServerException(
            message: data['message'] ?? 'Failed to search tasks',
            code: data['code'] ?? 500,
          );
        }
      } else {
        throw ServerException(
          message: 'Failed to search tasks',
          code: response.statusCode ?? 500,
        );
      }
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data['message'] ?? 'Network error occurred',
        code: e.response?.statusCode ?? 500,
      );
    }
  }
}
```

### Polling Strategy

**Constants:**

```dart
// lib/core/constants/app_constants.dart

class AppConstants {
  // Existing constants...
  
  // Task polling
  static const Duration taskPollingInterval = Duration(seconds: 3);
  static const int maxPollingRetries = 3;
}
```

**BLoC with Polling:**

```dart
// lib/features/audio_manager/presentation/bloc/task_monitor_bloc.dart

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

  TaskMonitorBloc({
    required this.searchTasks,
  }) : super(TaskMonitorInitial()) {
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
    // Start polling for all task types
    _startPolling();
    
    // Initial load
    add(const RefreshUploadTasks());
    add(const RefreshTranscribeTasks());
    add(const RefreshSummarizeTasks());
  }

  void _startPolling() {
    // Poll upload tasks
    _uploadPollingTimer = Timer.periodic(
      AppConstants.taskPollingInterval,
      (_) => add(const RefreshUploadTasks()),
    );

    // Poll transcribe tasks
    _transcribePollingTimer = Timer.periodic(
      AppConstants.taskPollingInterval,
      (_) => add(const RefreshTranscribeTasks()),
    );

    // Poll summarize tasks
    _summarizePollingTimer = Timer.periodic(
      AppConstants.taskPollingInterval,
      (_) => add(const RefreshSummarizeTasks()),
    );
  }

  Future<void> _onStopMonitoring(
    StopTaskMonitoring event,
    Emitter<TaskMonitorState> emit,
  ) async {
    _stopPolling();
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
      (failure) {
        // Keep existing state, just log error
        // Don't emit error to avoid UI disruption during polling
      },
      (tasks) {
        if (state is TasksLoaded) {
          emit((state as TasksLoaded).copyWithUploadTasks(tasks));
        } else {
          emit(TasksLoaded(
            uploadTasks: tasks,
            transcribeTasks: const [],
            summarizeTasks: const [],
          ));
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
      (failure) {
        // Keep existing state
      },
      (tasks) {
        if (state is TasksLoaded) {
          emit((state as TasksLoaded).copyWithTranscribeTasks(tasks));
        } else {
          emit(TasksLoaded(
            uploadTasks: const [],
            transcribeTasks: tasks,
            summarizeTasks: const [],
          ));
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
      (failure) {
        // Keep existing state
      },
      (tasks) {
        if (state is TasksLoaded) {
          emit((state as TasksLoaded).copyWithSummarizeTasks(tasks));
        } else {
          emit(TasksLoaded(
            uploadTasks: const [],
            transcribeTasks: const [],
            summarizeTasks: tasks,
          ));
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
```

**Events:**

```dart
// lib/features/audio_manager/presentation/bloc/task_monitor_event.dart

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
```

**States:**

```dart
// lib/features/audio_manager/presentation/bloc/task_monitor_state.dart

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
```

### UI Implementation - Tasks Tab

```dart
// lib/features/audio_manager/presentation/pages/tabs/tasks_tab.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/task_monitor_bloc.dart';
import '../../bloc/task_monitor_event.dart';
import '../../bloc/task_monitor_state.dart';
import '../../widgets/collapsible_section.dart';
import '../../widgets/loading_task_item.dart';

class TasksTab extends StatefulWidget {
  const TasksTab({super.key});

  @override
  State<TasksTab> createState() => _TasksTabState();
}

class _TasksTabState extends State<TasksTab> {
  @override
  void initState() {
    super.initState();
    // Start monitoring when tab opens
    context.read<TaskMonitorBloc>().add(const StartTaskMonitoring());
  }

  @override
  void dispose() {
    // Stop monitoring when tab closes
    context.read<TaskMonitorBloc>().add(const StopTaskMonitoring());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TaskMonitorBloc, TaskMonitorState>(
      builder: (context, state) {
        if (state is TasksLoaded) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Uploading section
                CollapsibleSection(
                  title: 'Uploading',
                  count: state.uploadTasks.length,
                  children: state.uploadTasks.map((task) {
                    return LoadingTaskItem(
                      icon: Icons.upload_file,
                      iconColor: Colors.orange,
                      title: task.filename,
                      description: 'Uploading...',
                      onTap: () => _showTaskNotification(context, 'Uploading'),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                
                // Transcribing section
                CollapsibleSection(
                  title: 'Transcribing',
                  count: state.transcribeTasks.length,
                  children: state.transcribeTasks.map((task) {
                    return LoadingTaskItem(
                      icon: Icons.description,
                      iconColor: Colors.blue,
                      title: task.filename,
                      description: 'Transcribing...',
                      onTap: () => _showTaskNotification(context, 'Transcribing'),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                
                // Summarizing section
                CollapsibleSection(
                  title: 'Summarizing',
                  count: state.summarizeTasks.length,
                  children: state.summarizeTasks.map((task) {
                    return LoadingTaskItem(
                      icon: Icons.summarize,
                      iconColor: Colors.green,
                      title: task.filename,
                      description: 'Summarizing...',
                      onTap: () => _showTaskNotification(context, 'Summarizing'),
                    );
                  }).toList(),
                ),
              ],
            ),
          );
        }

        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }

  void _showTaskNotification(BuildContext context, String taskType) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$taskType in progress...'),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
```

---

## Navigation Flow

### Update Recording Page

```dart
// lib/features/recording/presentation/pages/recording_page.dart

BlocListener<RecordingBloc, RecordingState>(
  listener: (context, state) {
    // ... existing listeners

    if (state is RecordingUploadSuccess) {
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          backgroundColor: Colors.green,
        ),
      );
      
      // Navigate to Audio Manager - Tasks Tab
      context.push(
        '${AppRoutes.audioManager}?tab=tasks',
      );
    }
  },
  child: // ... rest of UI
)
```

### Update Audio Manager Page

```dart
// lib/features/audio_manager/presentation/pages/audio_manager_page.dart

class AudioManagerPage extends StatefulWidget {
  final String? initialTab;
  
  const AudioManagerPage({
    super.key,
    this.initialTab,
  });

  @override
  State<AudioManagerPage> createState() => _AudioManagerPageState();
}

class _AudioManagerPageState extends State<AudioManagerPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    
    // Determine initial tab index
    int initialIndex = 0;
    if (widget.initialTab == 'tasks') {
      initialIndex = 1;
    } else if (widget.initialTab == 'pending') {
      initialIndex = 2;
    }
    
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: initialIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ... rest of implementation
}
```

### Update App Router

```dart
// lib/core/routes/app_router.dart

GoRoute(
  path: AppRoutes.audioManager,
  builder: (context, state) {
    final tab = state.uri.queryParameters['tab'];
    
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => sl<AudioManagerBloc>(),
        ),
        BlocProvider(
          create: (context) => sl<TaskMonitorBloc>(),
        ),
      ],
      child: AudioManagerPage(initialTab: tab),
    );
  },
),
```

---

## Complete Flow Summary

### 1. User Starts Recording

```
User taps Record button
  ↓
Show "2-hour limit" notification
  ↓
Start recording
  ↓
Set 2-hour auto-stop timer
  ↓
Monitor duration
```

### 2. Recording Completes (Manual or Auto)

```
Recording stops (user or 2-hour limit)
  ↓
Get audio file
  ↓
Trigger upload event
  ↓
Upload to /audio/upload-async
  ↓
Receive job_id
  ↓
Navigate to Audio Manager (Tasks tab)
```

### 3. Task Monitoring

```
Tasks tab opens
  ↓
Start polling timers (3-second interval)
  ↓
Poll /tasks/search for each type:
  - upload tasks
  - transcribe tasks
  - summarize tasks
  ↓
Update UI with task statuses
  ↓
Continue polling until user leaves
  ↓
Stop all timers when tab closes
```

---

## Dependency Injection

Update `injection_container.dart`:

```dart
// Recording feature
sl.registerLazySingleton(() => UploadRecordingAsync(sl()));

sl.registerLazySingleton<RecordingRemoteDataSource>(
  () => RecordingRemoteDataSourceImpl(dio: sl()),
);

// Audio Manager feature
sl.registerFactory(
  () => TaskMonitorBloc(searchTasks: sl()),
);

sl.registerLazySingleton(() => SearchTasks(sl()));

sl.registerLazySingleton<AudioManagerRepository>(
  () => AudioManagerRepositoryImpl(
    remoteDataSource: sl(),
    networkInfo: sl(),
    authLocalDataSource: sl(),
  ),
);

sl.registerLazySingleton<AudioManagerRemoteDataSource>(
  () => AudioManagerRemoteDataSourceImpl(dio: sl()),
);
```

---

## Error Handling

### Network Errors During Polling

```dart
// Don't show errors during background polling
// Just maintain existing state and retry on next interval

Future<void> _onRefreshUploadTasks(
  RefreshUploadTasks event,
  Emitter<TaskMonitorState> emit,
) async {
  try {
    final result = await searchTasks(criteria);
    result.fold(
      (failure) {
        // Silent fail - keep existing data
        // Next poll will retry
      },
      (tasks) {
        // Update state with new tasks
      },
    );
  } catch (e) {
    // Silent fail during polling
  }
}
```

### Upload Errors

```dart
// Show clear error messages for upload failures

if (state is RecordingError) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(state.message),
      backgroundColor: Colors.red,
      action: SnackBarAction(
        label: 'Retry',
        onPressed: () {
          // Retry upload
          context.read<RecordingBloc>().add(
            UploadRecordingRequested(lastAudioFile),
          );
        },
      ),
    ),
  );
}
```

---

## Testing Checklist

### Recording Tests

- [ ] 2-hour limit notification shows on recording start
- [ ] Auto-stop triggers after 2 hours
- [ ] Manual stop before 2 hours works
- [ ] Audio file is properly saved
- [ ] Upload triggers after recording completes

### Upload Tests

- [ ] File uploads successfully to /audio/upload-async
- [ ] job_id is received and stored
- [ ] Navigation to Tasks tab occurs
- [ ] Error handling for failed uploads
- [ ] Retry mechanism works

### Polling Tests

- [ ] Polling starts when Tasks tab opens
- [ ] Three separate timers run for each task type
- [ ] 3-second interval is maintained
- [ ] Polling stops when leaving tab
- [ ] No memory leaks from timers
- [ ] UI updates with new task data
- [ ] Silent error handling during polling

### UI Tests

- [ ] Tasks display in correct sections
- [ ] Loading animations show for active tasks
- [ ] Collapsible sections work
- [ ] Task counts are accurate
- [ ] Notification shows when tapping tasks
- [ ] Navigation back works properly

---

## Performance Considerations

1. **Polling Efficiency**: Use 3-second intervals to balance freshness and performance
2. **Memory Management**: Cancel timers in dispose() to prevent leaks
3. **Network Optimization**: Consider exponential backoff for failed requests
4. **State Updates**: Use copyWith to minimize rebuilds
5. **Large Lists**: Use ListView.builder for task lists if count exceeds 50

---

## Best Practices

1. **Clear User Feedback**: Always inform user of recording limits and upload status
2. **Resource Cleanup**: Stop polling when not needed
3. **Error Recovery**: Implement retry mechanisms for uploads
4. **State Persistence**: Consider caching task data locally
5. **Progressive Enhancement**: Show loading states during initial data fetch

---

**End of Document**
