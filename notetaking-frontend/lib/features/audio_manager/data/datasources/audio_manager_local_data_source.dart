import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/audio_file_page_model.dart';
import '../../domain/entities/server_task_bucket.dart';
import '../../domain/entities/pending_task.dart';
import '../../domain/entities/pending_task_bucket.dart';
import '../../domain/entities/server_task.dart';
import '../models/server_task_model.dart';
import '../models/pending_task_model.dart';

abstract class AudioManagerLocalDataSource {
  Future<void> cacheAudioFiles(AudioFilePageModel page);
  Future<AudioFilePageModel?> getCachedAudioFiles();
  Future<void> cacheServerTasks(ServerTaskBucket bucket);
  Future<ServerTaskBucket?> getCachedServerTasks();
  Future<void> cachePendingTasks(PendingTaskBucket bucket);
  Future<PendingTaskBucket?> getCachedPendingTasks();
}

class AudioManagerLocalDataSourceImpl implements AudioManagerLocalDataSource {
  static const _audioFilesKey = 'audio_manager_audio_files';
  static const _serverTasksKey = 'audio_manager_server_tasks';
  static const _pendingTasksKey = 'audio_manager_pending_tasks';

  final SharedPreferences sharedPreferences;

  AudioManagerLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<void> cacheAudioFiles(AudioFilePageModel page) async {
    final data = {
      'items': page.items.map((item) => (item as dynamic).toJson()).toList(),
      'total': page.total,
      'page': page.page,
      'limit': page.limit,
    };
    await sharedPreferences.setString(_audioFilesKey, json.encode(data));
  }

  @override
  Future<AudioFilePageModel?> getCachedAudioFiles() async {
    final raw = sharedPreferences.getString(_audioFilesKey);
    if (raw == null) {
      return null;
    }
    final jsonMap = json.decode(raw) as Map<String, dynamic>;
    return AudioFilePageModel.fromJson(jsonMap);
  }

  @override
  Future<void> cacheServerTasks(ServerTaskBucket bucket) async {
    final data = {
      'uploading': bucket.uploading
          .map((item) => _serverTaskToJson(item))
          .toList(),
      'transcribing': bucket.transcribing
          .map((item) => _serverTaskToJson(item))
          .toList(),
      'summarizing': bucket.summarizing
          .map((item) => _serverTaskToJson(item))
          .toList(),
    };
    await sharedPreferences.setString(_serverTasksKey, json.encode(data));
  }

  @override
  Future<ServerTaskBucket?> getCachedServerTasks() async {
    final raw = sharedPreferences.getString(_serverTasksKey);
    if (raw == null) {
      return null;
    }
    final jsonMap = json.decode(raw) as Map<String, dynamic>;
    final uploading = (jsonMap['uploading'] as List<dynamic>? ?? [])
        .map(
          (item) => ServerTaskModel.fromJson(
            item as Map<String, dynamic>,
            type: ServerTaskType.uploading,
          ),
        )
        .toList();
    final transcribing = (jsonMap['transcribing'] as List<dynamic>? ?? [])
        .map(
          (item) => ServerTaskModel.fromJson(
            item as Map<String, dynamic>,
            type: ServerTaskType.transcribing,
          ),
        )
        .toList();
    final summarizing = (jsonMap['summarizing'] as List<dynamic>? ?? [])
        .map(
          (item) => ServerTaskModel.fromJson(
            item as Map<String, dynamic>,
            type: ServerTaskType.summarizing,
          ),
        )
        .toList();

    return ServerTaskBucket(
      uploading: uploading,
      transcribing: transcribing,
      summarizing: summarizing,
    );
  }

  @override
  Future<void> cachePendingTasks(PendingTaskBucket bucket) async {
    final data = {
      'untranscribed_audios': bucket.untranscribedAudios
          .map((item) => _pendingTaskToJson(item))
          .toList(),
      'unsummarized_transcripts': bucket.unsummarizedTranscripts
          .map((item) => _pendingTaskToJson(item))
          .toList(),
    };
    await sharedPreferences.setString(_pendingTasksKey, json.encode(data));
  }

  @override
  Future<PendingTaskBucket?> getCachedPendingTasks() async {
    final raw = sharedPreferences.getString(_pendingTasksKey);
    if (raw == null) {
      return null;
    }
    final jsonMap = json.decode(raw) as Map<String, dynamic>;
    final untranscribed =
        (jsonMap['untranscribed_audios'] as List<dynamic>? ?? [])
            .map(
              (item) => PendingTaskModel.fromUntranscribedJson(
                item as Map<String, dynamic>,
              ),
            )
            .toList();
    final unsummarized =
        (jsonMap['unsummarized_transcripts'] as List<dynamic>? ?? [])
            .map(
              (item) => PendingTaskModel.fromUnsummarizedJson(
                item as Map<String, dynamic>,
              ),
            )
            .toList();

    return PendingTaskBucket(
      untranscribedAudios: untranscribed,
      unsummarizedTranscripts: unsummarized,
    );
  }

  Map<String, dynamic> _serverTaskToJson(ServerTask task) {
    return {
      'task_id': task.taskId,
      'filename': task.filename,
      'status': task.status,
      'progress': task.progress,
      'started_at': task.startedAt?.toIso8601String(),
      'audio_id': task.audioId,
      'transcription_id': task.transcriptionId,
    };
  }

  Map<String, dynamic> _pendingTaskToJson(PendingTask task) {
    if (task.type == PendingTaskType.untranscribedAudio) {
      return {
        'audio_id': task.id,
        'filename': task.title,
        'upload_date': task.date?.toIso8601String(),
        'file_size': task.fileSize,
      };
    }

    return {
      'transcription_id': task.id,
      'audio_filename': task.title,
      'transcription_date': task.date?.toIso8601String(),
      'word_count': task.wordCount,
    };
  }
}
