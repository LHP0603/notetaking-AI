import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/supabase/supabase_client.dart';
import '../../../../core/supabase/supabase_config.dart';
import '../models/recording_model.dart';
import '../models/marker_model.dart';
import '../models/recording_tag_model.dart';
import '../models/export_job_model.dart';

abstract class RecordingRemoteDataSource {
  /// Upload audio file to Supabase Storage
  Future<String> uploadAudioToSupabase({
    required File audioFile,
    required String userId,
    required String recordingId,
  });
  Future<RecordingModel> createRecording({
    required String? folderId,
    required String title,
    required String sourceType,
  });
  Future<RecordingModel> completeUpload({
    required String recordingId,
    required String filePath,
    required double fileSizeMb,
    required double durationSeconds,
    required String originalFileName,
  });
  Future<void> transcribeRecording(String recordingId);
  Future<List<RecordingModel>> getRecordings({
    String? folderId,
    bool? isTrashed,
    String? search,
    String? tag,
    int? page,
    int? pageSize,
  });
  Future<RecordingModel> getRecordingDetail(String recordingId);
  Future<RecordingModel> updateRecording({
    required String recordingId,
    String? title,
    String? folderId,
    bool? isPinned,
    double? lastPlayPosition,
  });
  Future<void> softDeleteRecording(String recordingId);
  Future<RecordingModel> restoreRecording(String recordingId);
  Future<void> hardDeleteRecording(String recordingId);

  // Markers
  Future<MarkerModel> createMarker({
    required String recordingId,
    required double timeSeconds,
    required String label,
    required String type,
    String? description,
  });
  Future<List<MarkerModel>> getMarkers(String recordingId);
  Future<MarkerModel> updateMarker({
    required int markerId,
    String? label,
    String? type,
    String? description,
  });
  Future<void> deleteMarker(int markerId);
  Future<ExportJobModel> exportRecording(String recordingId, String exportType);
  Future<ExportJobModel> getExportJob(String exportId);

  // Tags
  Future<List<RecordingTagModel>> addTags({
    required String recordingId,
    required List<String> tags,
  });
  Future<void> removeTag({required String recordingId, required String tag});
  Future<List<RecordingTagModel>> getTags(String recordingId);
}

class RecordingRemoteDataSourceImpl implements RecordingRemoteDataSource {
  final Dio dio;
  final SupabaseClient supabaseClient;

  RecordingRemoteDataSourceImpl({
    required this.dio,
    required this.supabaseClient,
  });

  @override
  Future<String> uploadAudioToSupabase({
    required File audioFile,
    required String
    userId, // Database user_id (kept for metadata, but not used for path)
    required String recordingId,
  }) async {
    try {
      // Get Supabase Auth user ID for storage path (required for RLS policies)
      // RLS policies check against auth.uid(), not database user_id
      // IMPORTANT: Sync auth state first to ensure session is established
      await supabaseClient.syncAuthState();

      final supabase = supabaseClient.supabase.client;

      // Try to get user ID from currentUser first
      var supabaseAuthUserId = supabase.auth.currentUser?.id;

      // If currentUser is null, try to get from currentSession
      if (supabaseAuthUserId == null || supabaseAuthUserId.isEmpty) {
        final currentSession = supabase.auth.currentSession;
        if (currentSession != null && currentSession.user.id.isNotEmpty) {
          supabaseAuthUserId = currentSession.user.id;
          print(
            'Info: Using session user ID (currentUser was null): $supabaseAuthUserId',
          );
        }
      }

      if (supabaseAuthUserId == null || supabaseAuthUserId.isEmpty) {
        throw Exception(
          'Cannot upload: Supabase Auth user ID is not available. '
          'Please ensure you are logged in via Supabase Auth. '
          'Session exists: ${supabase.auth.currentSession != null}',
        );
      }

      print(
        'Info: Using Supabase Auth user ID for storage path: $supabaseAuthUserId '
        '(database user_id: $userId)',
      );

      // Read file bytes
      final fileBytes = await audioFile.readAsBytes();

      // Generate unique file name
      final originalFileName = audioFile.path.split('/').last;
      final fileName = SupabaseConfig.generateFileName(originalFileName);

      // Generate storage path using Supabase Auth user ID 
      final storagePath = SupabaseConfig.recordingPath(
        supabaseAuthUserId, 
        recordingId,
        fileName,
      );

      print(
        'Info: Generated storage path: $storagePath (first segment: ${storagePath.split('/').isNotEmpty ? storagePath.split('/')[0] : "empty"})',
      );

      // Determine content type
      final extension = originalFileName.split('.').last.toLowerCase();
      final contentType = _getContentType(extension);

      // Upload to Supabase Storage
      final storagePathResult = await supabaseClient.uploadFile(
        bucket: SupabaseConfig.audioBucket,
        path: storagePath,
        fileBytes: fileBytes,
        contentType: contentType,
        metadata: {
          'original_filename': originalFileName,
          'recording_id': recordingId,
          'user_id': userId,
        },
      );

      return storagePathResult;
    } catch (e) {
      throw Exception('Failed to upload audio to Supabase: $e');
    }
  }

  String _getContentType(String extension) {
    switch (extension) {
      case 'm4a':
        return 'audio/mp4';
      case 'mp3':
        return 'audio/mpeg';
      case 'wav':
        return 'audio/wav';
      case 'aac':
        return 'audio/aac';
      case 'ogg':
        return 'audio/ogg';
      default:
        return 'audio/mpeg';
    }
  }

  @override
  Future<RecordingModel> createRecording({
    required String? folderId,
    required String title,
    required String sourceType,
  }) async {
    try {
      // Build request data - only include folder_id if it's not null
      final requestData = <String, dynamic>{
        'title': title,
        'source_type': sourceType,
      };

      // Only include folder_id if it's not null 
      if (folderId != null) {
        requestData['folder_id'] = folderId;
      }

      if (kDebugMode) {
        debugPrint(
          'Creating recording: POST ${AppConstants.recordingsEndpoint}',
        );
        debugPrint('Request data: $requestData');
      }

      final response = await dio.post(
        AppConstants.recordingsEndpoint,
        data: requestData,
      );

      if (response.statusCode == 201) {
        return RecordingModel.fromJson(response.data);
      } else {
        // Extract error message from response body
        final responseData = response.data;
        String errorMessage = 'Unexpected status code: ${response.statusCode}';

        if (responseData != null) {
          if (responseData is Map) {
            final detail = responseData['detail'];
            if (detail != null) {
              if (detail is List) {
                errorMessage = detail
                    .map((e) => e is Map ? e['msg']?.toString() : e.toString())
                    .where((msg) => msg != null)
                    .join(', ');
              } else {
                errorMessage = detail.toString();
              }
            } else {
              errorMessage =
                  responseData['message']?.toString() ??
                  responseData.toString();
            }
          } else {
            errorMessage = responseData.toString();
          }
        }

        final detailedError = 'Status ${response.statusCode}: $errorMessage';

        // Log unexpected status codes for debugging
        if (kDebugMode) {
          debugPrint('Error creating recording: $detailedError');
          debugPrint('Request URL: ${response.requestOptions.uri}');
          debugPrint('Request data: ${response.requestOptions.data}');
          debugPrint('Response status: ${response.statusCode}');
          debugPrint('Response data: $responseData');
        }

        // Throw appropriate exception based on status code
        if (response.statusCode == 400) {
          throw ValidationException(detailedError);
        } else if (response.statusCode == 401) {
          throw UnauthorizedException(detailedError);
        } else {
          throw ServerException(detailedError);
        }
      }
    } on DioException catch (e) {
      // Extract detailed error information
      final statusCode = e.response?.statusCode;
      final responseData = e.response?.data;

      // Try to extract error message from backend response
      String errorMessage = 'Network error';
      if (responseData != null) {
        if (responseData is Map) {
          final detail = responseData['detail'];
          if (detail != null) {
            if (detail is List) {
              errorMessage = detail
                  .map((e) => e is Map ? e['msg']?.toString() : e.toString())
                  .where((msg) => msg != null)
                  .join(', ');
            } else {
              errorMessage = detail.toString();
            }
          } else {
            errorMessage =
                responseData['message']?.toString() ?? responseData.toString();
          }
        } else {
          errorMessage = responseData.toString();
        }
      } else if (e.message != null) {
        errorMessage = e.message!;
      }

      final detailedError =
          statusCode != null
              ? 'Status $statusCode: $errorMessage'
              : errorMessage;

      if (kDebugMode) {
        debugPrint('Error creating recording: $detailedError');
        debugPrint('Request URL: ${e.requestOptions.uri}');
        debugPrint('Request data: ${e.requestOptions.data}');
        debugPrint('Response status: $statusCode');
        debugPrint('Response data: $responseData');
      }

      // Throw appropriate exception based on status code
      if (statusCode == 401) {
        throw UnauthorizedException(detailedError);
      } else if (statusCode == 400) {
        throw ValidationException(detailedError);
      } else if (statusCode != null) {
        throw ServerException(detailedError);
      } else {
        throw NetworkException(detailedError);
      }
    } catch (e) {
      if (e is ServerException ||
          e is UnauthorizedException ||
          e is ValidationException ||
          e is NetworkException) {
        rethrow;
      }
      throw ServerException('Failed to create recording: $e');
    }
  }

  @override
  Future<RecordingModel> completeUpload({
    required String recordingId,
    required String filePath,
    required double fileSizeMb,
    required double durationSeconds,
    required String originalFileName,
  }) async {
    try {
      final requestData = {
        'file_path': filePath,
        'file_size_mb': fileSizeMb,
        'duration_seconds': durationSeconds,
        'original_file_name': originalFileName,
      };

      final url =
          '${AppConstants.recordingsEndpoint.replaceAll(RegExp(r'/$'), '')}/$recordingId/complete-upload';

      if (kDebugMode) {
        debugPrint('Completing upload: POST $url');
        debugPrint('Request data: $requestData');
      }

      final response = await dio.post(url, data: requestData);

      if (response.statusCode == 200) {
        return RecordingModel.fromJson(response.data);
      } else {
        throw ServerException('Unexpected status code: ${response.statusCode}');
      }
    } on DioException catch (e) {
      // Extract detailed error information
      final statusCode = e.response?.statusCode;
      final responseData = e.response?.data;

      // Try to extract error message from backend response
      String errorMessage = 'Network error';
      if (responseData != null) {
        if (responseData is Map) {
          errorMessage =
              responseData['detail']?.toString() ??
              responseData['message']?.toString() ??
              responseData.toString();
        } else {
          errorMessage = responseData.toString();
        }
      } else if (e.message != null) {
        errorMessage = e.message!;
      }

      final detailedError =
          statusCode != null
              ? 'Status $statusCode: $errorMessage'
              : errorMessage;

      if (kDebugMode) {
        debugPrint('Error completing upload: $detailedError');
        debugPrint('Request URL: ${e.requestOptions.uri}');
        debugPrint('Request data: ${e.requestOptions.data}');
        debugPrint('Response status: $statusCode');
        debugPrint('Response data: $responseData');
      }

      // Throw appropriate exception based on status code
      if (statusCode == 401) {
        throw UnauthorizedException(detailedError);
      } else if (statusCode == 400) {
        throw ValidationException(detailedError);
      } else if (statusCode != null) {
        throw ServerException(detailedError);
      } else {
        throw NetworkException(detailedError);
      }
    } catch (e) {
      if (e is ServerException ||
          e is UnauthorizedException ||
          e is ValidationException ||
          e is NetworkException) {
        rethrow;
      }
      throw ServerException('Failed to complete upload: $e');
    }
  }

  @override
  Future<void> transcribeRecording(String recordingId) async {
    try {
      final url =
          '${AppConstants.recordingsEndpoint.replaceAll(RegExp(r'/$'), '')}/$recordingId/transcribe';

      if (kDebugMode) {
        debugPrint('Transcribing recording: POST $url');
      }

      final response = await dio.post(url);

      // Backend returns 202 Accepted for async transcription
      if (response.statusCode == 202) {
        return;
      } else {
        throw ServerException('Unexpected status code: ${response.statusCode}');
      }
    } on DioException catch (e) {
      // Extract detailed error information
      final statusCode = e.response?.statusCode;
      final responseData = e.response?.data;

      // Try to extract error message from backend response
      String errorMessage = 'Network error';
      if (responseData != null) {
        if (responseData is Map) {
          errorMessage =
              responseData['detail']?.toString() ??
              responseData['message']?.toString() ??
              responseData.toString();
        } else {
          errorMessage = responseData.toString();
        }
      } else if (e.message != null) {
        errorMessage = e.message!;
      }

      final detailedError =
          statusCode != null
              ? 'Status $statusCode: $errorMessage'
              : errorMessage;

      if (kDebugMode) {
        debugPrint('Error transcribing recording: $detailedError');
        debugPrint('Request URL: ${e.requestOptions.uri}');
        debugPrint('Response status: $statusCode');
        debugPrint('Response data: $responseData');
      }

      // Throw appropriate exception based on status code
      if (statusCode == 401) {
        throw UnauthorizedException(detailedError);
      } else if (statusCode == 400) {
        throw ValidationException(detailedError);
      } else if (statusCode != null) {
        throw ServerException(detailedError);
      } else {
        throw NetworkException(detailedError);
      }
    } catch (e) {
      if (e is ServerException ||
          e is UnauthorizedException ||
          e is ValidationException ||
          e is NetworkException) {
        rethrow;
      }
      throw ServerException('Failed to transcribe recording: $e');
    }
  }

  @override
  Future<List<RecordingModel>> getRecordings({
    String? folderId,
    bool? isTrashed,
    String? search,
    String? tag,
    int? page,
    int? pageSize,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (folderId != null) queryParams['folder_id'] = folderId;
      if (isTrashed != null) queryParams['is_trashed'] = isTrashed;
      if (search != null) queryParams['search'] = search;
      if (tag != null) queryParams['tag'] = tag;
      if (page != null) queryParams['page'] = page;
      if (pageSize != null) queryParams['page_size'] = pageSize;

      final response = await dio.get(
        AppConstants.recordingsEndpoint,
        queryParameters: queryParams,
      );
      if (response.statusCode == 200) {
        return (response.data as List)
            .map((json) => RecordingModel.fromJson(json))
            .toList();
      } else {
        throw Exception('Failed to get recordings');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }

  @override
  Future<RecordingModel> getRecordingDetail(String recordingId) async {
    try {
      final response = await dio.get(
        '${AppConstants.recordingsEndpoint.replaceAll(RegExp(r'/$'), '')}/$recordingId',
      );
      if (response.statusCode == 200) {
        return RecordingModel.fromJson(response.data);
      } else {
        throw Exception('Failed to get recording detail');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }

  @override
  Future<RecordingModel> updateRecording({
    required String recordingId,
    String? title,
    String? folderId,
    bool? isPinned,
    double? lastPlayPosition,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (title != null) data['title'] = title;
      final hasOtherUpdates =
          title != null || isPinned != null || lastPlayPosition != null;
      if (folderId != null) {
        // Has a value, include it
        data['folder_id'] = folderId;
      } else if (!hasOtherUpdates) {
        // No other updates, assume folderId is being explicitly set to null (move to root)
        data['folder_id'] = null;
      }
      if (isPinned != null) data['is_pinned'] = isPinned;
      if (lastPlayPosition != null)
        data['last_play_position'] = lastPlayPosition;

      final response = await dio.patch(
        '${AppConstants.recordingsEndpoint.replaceAll(RegExp(r'/$'), '')}/$recordingId',
        data: data,
      );
      if (response.statusCode == 200) {
        return RecordingModel.fromJson(response.data);
      } else {
        throw Exception('Failed to update recording');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }

  @override
  Future<void> softDeleteRecording(String recordingId) async {
    try {
      final response = await dio.delete(
        '${AppConstants.recordingsEndpoint.replaceAll(RegExp(r'/$'), '')}/$recordingId',
      );
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to soft delete recording');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }

  @override
  Future<RecordingModel> restoreRecording(String recordingId) async {
    try {
      final response = await dio.post(
        '${AppConstants.recordingsEndpoint.replaceAll(RegExp(r'/$'), '')}/$recordingId/restore',
      );
      if (response.statusCode == 200) {
        return RecordingModel.fromJson(response.data);
      } else {
        throw Exception('Failed to restore recording');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }

  @override
  Future<void> hardDeleteRecording(String recordingId) async {
    try {
      final response = await dio.delete(
        '${AppConstants.recordingsEndpoint.replaceAll(RegExp(r'/$'), '')}/$recordingId/hard-delete',
      );
      if (response.statusCode != 204) {
        throw Exception('Failed to hard delete recording');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }

  @override
  Future<MarkerModel> createMarker({
    required String recordingId,
    required double timeSeconds,
    required String label,
    required String type,
    String? description,
  }) async {
    try {
      final response = await dio.post(
        '${AppConstants.recordingsEndpoint.replaceAll(RegExp(r'/$'), '')}/$recordingId/markers',
        data: {
          'time_seconds': timeSeconds,
          'label': label,
          'type': type,
          'description': description,
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return MarkerModel.fromJson(response.data);
      } else {
        throw Exception('Failed to create marker');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }

  @override
  Future<List<MarkerModel>> getMarkers(String recordingId) async {
    try {
      final response = await dio.get(
        '${AppConstants.recordingsEndpoint.replaceAll(RegExp(r'/$'), '')}/$recordingId/markers',
      );
      if (response.statusCode == 200) {
        return (response.data as List)
            .map((json) => MarkerModel.fromJson(json))
            .toList();
      } else {
        throw Exception('Failed to get markers');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }

  @override
  Future<MarkerModel> updateMarker({
    required int markerId,
    String? label,
    String? type,
    String? description,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (label != null) data['label'] = label;
      if (type != null) data['type'] = type;
      if (description != null) data['description'] = description;

      final response = await dio.patch(
        '${AppConstants.markersEndpoint}/$markerId',
        data: data,
      );
      if (response.statusCode == 200) {
        return MarkerModel.fromJson(response.data);
      } else {
        throw Exception('Failed to update marker');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }

  @override
  Future<void> deleteMarker(int markerId) async {
    try {
      final response = await dio.delete(
        '${AppConstants.markersEndpoint}/$markerId',
      );
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete marker');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }

  @override
  Future<ExportJobModel> exportRecording(
    String recordingId,
    String exportType,
  ) async {
    try {
      final response = await dio.post(
        '/recordings/$recordingId/export',
        data: {'recording_id': recordingId, 'export_type': exportType},
      );
      return ExportJobModel.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }

  Future<ExportJobModel> getExportJob(String exportId) async {
    try {
      // Backend router is mounted at /recordings, so full path is /recordings/export-jobs/{id}
      final response = await dio.get('/recordings/export-jobs/$exportId');
      return ExportJobModel.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }

  @override
  Future<List<RecordingTagModel>> addTags({
    required String recordingId,
    required List<String> tags,
  }) async {
    try {
      final response = await dio.post(
        '${AppConstants.recordingsEndpoint.replaceAll(RegExp(r'/$'), '')}/$recordingId/tags',
        data: {'tags': tags},
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return (response.data as List)
            .map((json) => RecordingTagModel.fromJson(json))
            .toList();
      } else {
        throw Exception('Failed to add tags');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }

  @override
  Future<void> removeTag({
    required String recordingId,
    required String tag,
  }) async {
    try {
      final response = await dio.delete(
        '${AppConstants.recordingsEndpoint.replaceAll(RegExp(r'/$'), '')}/$recordingId/tags/$tag',
      );
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to remove tag');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }

  @override
  Future<List<RecordingTagModel>> getTags(String recordingId) async {
    try {
      final response = await dio.get(
        '${AppConstants.recordingsEndpoint.replaceAll(RegExp(r'/$'), '')}/$recordingId/tags',
      );
      if (response.statusCode == 200) {
        return (response.data as List)
            .map((json) => RecordingTagModel.fromJson(json))
            .toList();
      } else {
        throw Exception('Failed to get tags');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }
}
