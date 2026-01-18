import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/audio_filter_model.dart';
import '../models/audio_file_model.dart';
import '../models/audio_file_page_model.dart';
import '../models/audio_upload_result_model.dart';
import '../models/note_model.dart';
import '../models/pending_task_model.dart';
import '../models/server_task_model.dart';
import '../models/task_model.dart';
import '../../domain/entities/server_task.dart';
import '../../domain/entities/pending_task_bucket.dart';
import '../../domain/entities/server_task_bucket.dart';
import '../../domain/entities/task_search_criteria.dart';

abstract class AudioManagerRemoteDataSource {
  Future<AudioFilePageModel> getAudioFiles(AudioFilterModel filter);
  Future<AudioFileModel> getAudioFileById(int audioId);
  Future<AudioUploadResultModel> uploadAudioFile(File audioFile);
  Future<AudioFileModel> renameAudio(int audioId, String newName);
  Future<void> deleteAudio(int audioId);
  Future<String> downloadAudio(int audioId, String filename);
  Future<List<TaskModel>> getActiveTasks(int audioId);
  Future<AudioFileModel> updateTranscription(
    int audioId,
    String transcription,
  );
  Future<void> startTranscription(int audioId);
  Future<NoteModel?> getSummaryNote(int audioFileId);
  Future<NoteModel> getNoteById(int noteId);
  Future<void> startSummarization(int audioFileId);
  Future<NoteModel> updateNoteSummary(int noteId, String summary);
  Future<ServerTaskBucket> getServerTasks();
  Future<PendingTaskBucket> getPendingTasks();
  Future<List<TaskModel>> searchTasks(TaskSearchCriteria criteria);
}

class AudioManagerRemoteDataSourceImpl implements AudioManagerRemoteDataSource {
  final Dio dio;

  AudioManagerRemoteDataSourceImpl({required this.dio});

  @override
  Future<AudioFilePageModel> getAudioFiles(AudioFilterModel filter) async {
    try {
      final response = await dio.post(
        AppConstants.audioSearchEndpoint,
        data: filter.toSearchBody(),
      );

      final data = _extractData(
        response,
        fallbackMessage: 'Failed to search audio files',
      );

      if (data is List) {
        return AudioFilePageModel.fromJson({
          'items': data,
          'total': data.length,
          'page': 1,
          'limit': data.length,
        });
      } else if (data is Map<String, dynamic>) {
        return AudioFilePageModel.fromJson(data);
      }
      
      throw const ServerException('Invalid response data structure');
    } on DioException catch (e) {
      throw _handleDioException(
        e,
        fallbackMessage: 'Failed to search audio files',
      );
    }
  }

  @override
  Future<AudioFileModel> getAudioFileById(int audioId) async {
    try {
      final response = await dio.get(AppConstants.audioFileById(audioId));

      final data = _extractData(
        response,
        fallbackMessage: 'Failed to load audio details',
      );

      return AudioFileModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioException(
        e,
        fallbackMessage: 'Failed to load audio details',
      );
    }
  }

  @override
  Future<AudioUploadResultModel> uploadAudioFile(File audioFile) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          audioFile.path,
          filename: audioFile.path.split('/').last,
        ),
      });

      final response = await dio.post(
        AppConstants.audioUploadAsyncEndpoint,
        data: formData,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
      );

      final data = _extractData(
        response,
        fallbackMessage: 'Failed to upload audio',
      );
      return AudioUploadResultModel.fromJson(data);
    } on DioException catch (e) {
      throw _handleDioException(e, fallbackMessage: 'Failed to upload audio');
    }
  }

  @override
  Future<AudioFileModel> renameAudio(int audioId, String newName) async {
    try {
      final response = await dio.put(
        AppConstants.updateAudio(audioId),
        data: {'original_filename': newName},
      );

      final data = _extractData(
        response,
        fallbackMessage: 'Failed to rename audio',
      );

      return AudioFileModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioException(e, fallbackMessage: 'Failed to rename audio');
    }
  }

  @override
  Future<void> deleteAudio(int audioId) async {
    try {
      final response = await dio.delete(AppConstants.deleteAudio(audioId));

      _extractData(
        response,
        fallbackMessage: 'Failed to delete audio',
      );
    } on DioException catch (e) {
      throw _handleDioException(e, fallbackMessage: 'Failed to delete audio');
    }
  }

  @override
  Future<String> downloadAudio(int audioId, String filename) async {
    try {
      final response = await dio.get(
        AppConstants.downloadAudio(audioId),
        options: Options(responseType: ResponseType.bytes),
      );

      final directory = await getApplicationDocumentsDirectory();
      final normalizedName =
          filename.trim().isEmpty ? 'audio.mp3' : filename.trim();
      final filePath = '${directory.path}/$normalizedName';
      final file = File(filePath);
      await file.writeAsBytes(response.data as List<int>);

      return filePath;
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        final message = data['message']?.toString() ?? 'File not found';
        throw ServerException(
          message,
          code: data['code'] is int
              ? data['code'] as int
              : e.response?.statusCode ?? 500,
        );
      }
      throw _handleDioException(e, fallbackMessage: 'Failed to download audio');
    }
  }

  @override
  Future<List<TaskModel>> getActiveTasks(int audioId) async {
    try {
      final response = await dio.post(
        AppConstants.searchTasksEndpoint,
        data: {
          'active_only': true,
          'audio_id': audioId,
          'order': 'DESC',
          'page': 1,
          'page_size': 10,
        },
      );

      final data = _extractData(
        response,
        fallbackMessage: 'Failed to load tasks',
      );

      final taskItems = data['data'];
      if (taskItems is! List) {
        throw const ServerException('Invalid response data');
      }

      return taskItems
          .map(
            (item) => TaskModel.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    } on DioException catch (e) {
      throw _handleDioException(e, fallbackMessage: 'Failed to load tasks');
    }
  }

  @override
  Future<AudioFileModel> updateTranscription(
    int audioId,
    String transcription,
  ) async {
    try {
      final response = await dio.put(
        AppConstants.updateAudio(audioId),
        data: {'transcription': transcription},
      );

      final data = _extractData(
        response,
        fallbackMessage: 'Failed to update transcription',
      );

      return AudioFileModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioException(
        e,
        fallbackMessage: 'Failed to update transcription',
      );
    }
  }

  @override
  Future<void> startTranscription(int audioId) async {
    try {
      final response = await dio.post(
        AppConstants.transcribeAsyncEndpoint,
        data: {'audio_id': audioId, 'language_code': 'vi-VN'},
      );

      _extractData(
        response,
        fallbackMessage: 'Failed to start transcription',
      );
    } on DioException catch (e) {
      throw _handleDioException(
        e,
        fallbackMessage: 'Failed to start transcription',
      );
    }
  }

  @override
  Future<NoteModel?> getSummaryNote(int audioFileId) async {
    try {
      final response = await dio.post(
        AppConstants.searchNotesEndpoint,
        data: {'audio_file_id': audioFileId, 'page': 1, 'page_size': 1},
      );

      final data = _extractData(
        response,
        fallbackMessage: 'Failed to load summary',
      );

      final notes = data['data'];
      if (notes is! List) {
        throw const ServerException('Invalid response data');
      }
      if (notes.isEmpty) {
        return null;
      }
      return NoteModel.fromJson(notes.first as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioException(e, fallbackMessage: 'Failed to load summary');
    }
  }

  @override
  Future<NoteModel> getNoteById(int noteId) async {
    try {
      final response = await dio.get(AppConstants.updateNote(noteId));

      final data = _extractData(
        response,
        fallbackMessage: 'Failed to load note',
      );

      if (data is Map<String, dynamic>) {
        return NoteModel.fromJson(data);
      }

      throw const ServerException('Invalid response data');
    } on DioException catch (e) {
      throw _handleDioException(e, fallbackMessage: 'Failed to load note');
    }
  }

  @override
  Future<void> startSummarization(int audioFileId) async {
    try {
      final response = await dio.post(
        AppConstants.summarizeAsyncEndpoint,
        data: {'audio_file_id': audioFileId},
      );

      _extractData(
        response,
        fallbackMessage: 'Failed to start summarization',
      );
    } on DioException catch (e) {
      throw _handleDioException(
        e,
        fallbackMessage: 'Failed to start summarization',
      );
    }
  }

  @override
  Future<NoteModel> updateNoteSummary(int noteId, String summary) async {
    try {
      final response = await dio.put(
        AppConstants.updateNote(noteId),
        data: {'summary': summary},
      );

      final data = _extractData(
        response,
        fallbackMessage: 'Failed to update summary',
      );

      return NoteModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioException(e, fallbackMessage: 'Failed to update summary');
    }
  }

  @override
  Future<ServerTaskBucket> getServerTasks() async {
    try {
      final response = await dio.get(AppConstants.activeTasksEndpoint);

      final data = _extractData(
        response,
        fallbackMessage: 'Failed to load tasks',
      );

      final uploading = (data['uploading'] as List<dynamic>? ?? [])
          .map(
            (item) => ServerTaskModel.fromJson(
              item as Map<String, dynamic>,
              type: ServerTaskType.uploading,
            ),
          )
          .toList();
      final transcribing = (data['transcribing'] as List<dynamic>? ?? [])
          .map(
            (item) => ServerTaskModel.fromJson(
              item as Map<String, dynamic>,
              type: ServerTaskType.transcribing,
            ),
          )
          .toList();
      final summarizing = (data['summarizing'] as List<dynamic>? ?? [])
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
    } on DioException catch (e) {
      throw _handleDioException(e, fallbackMessage: 'Failed to load tasks');
    }
  }

  @override
  Future<PendingTaskBucket> getPendingTasks() async {
    try {
      final response = await dio.get(AppConstants.pendingTasksEndpoint);

      final data = _extractData(
        response,
        fallbackMessage: 'Failed to load pending tasks',
      );

      final untranscribed =
          (data['untranscribed_audios'] as List<dynamic>? ?? [])
              .map(
                (item) => PendingTaskModel.fromUntranscribedJson(
                  item as Map<String, dynamic>,
                ),
              )
              .toList();
      final unsummarized =
          (data['unsummarized_transcripts'] as List<dynamic>? ?? [])
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
    } on DioException catch (e) {
      throw _handleDioException(
        e,
        fallbackMessage: 'Failed to load pending tasks',
      );
    }
  }

  @override
  Future<List<TaskModel>> searchTasks(TaskSearchCriteria criteria) async {
    try {
      final response = await dio.post(
        AppConstants.searchTasksEndpoint,
        data: criteria.toJson(),
      );

      print('DEBUG: Response from ${AppConstants.searchTasksEndpoint} (searchTasks):');
      print(response.data);

      final data = _extractData(
        response,
        fallbackMessage: 'Failed to search tasks',
      );
      final taskItems = data['data'];
      if (taskItems is! List) {
        throw const ServerException('Invalid response data');
      }

      return taskItems
          .map(
            (item) =>
                TaskModel.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    } on DioException catch (e) {
      throw _handleDioException(
        e,
        fallbackMessage: 'Failed to search tasks',
      );
    }
  }

  dynamic _extractData(
    Response<dynamic> response, {
    required String fallbackMessage,
  }) {
    final payload = response.data;
    if (payload is! Map<String, dynamic>) {
      throw ServerException('Invalid response format');
    }

    final success = payload['success'] == true;
    final statusCode = response.statusCode ?? 500;
    if (statusCode >= 200 && statusCode < 300 && success) {
      return payload['data'];
    }

    final message = payload['message']?.toString() ?? fallbackMessage;
    final code = payload['code'] is int ? payload['code'] as int : statusCode;
    throw ServerException(message, code: code);
  }

  ServerException _handleDioException(
    DioException exception, {
    required String fallbackMessage,
  }) {
    final data = exception.response?.data;
    if (data is Map<String, dynamic>) {
      final message = data['message']?.toString() ??
          data['detail']?.toString() ??
          fallbackMessage;
      final code = data['code'] is int
          ? data['code'] as int
          : exception.response?.statusCode ?? 500;
      return ServerException(message, code: code);
    }
    return ServerException(
      fallbackMessage,
      code: exception.response?.statusCode ?? 500,
    );
  }
}
