import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/supabase/supabase_client.dart';
import '../../../../core/supabase/supabase_config.dart';
import '../models/audio_upload_response.dart';
import '../models/transcription_models.dart';

abstract class TranscriptionRemoteDataSource {
  Future<AudioUploadResponseModel> uploadAudio(File audioFile);
  Future<TranscriptionResponseModel> transcribeAudio(
    TranscriptionRequestModel request,
  );

  // Recording-based transcription (new API)
  Future<TranscriptionResponseModel> transcribeRecording(String recordingId);
  Future<List<TranscriptModel>> getTranscripts({
    required String recordingId,
    bool? latest,
  });
  Future<Map<String, dynamic>> getTranscriptDetail(String transcriptId);
  Future<TranscriptModel> updateTranscript({
    required String transcriptId,
    String? language,
    bool? isActive,
  });
  Future<TranscriptSegmentModel> updateSegment({
    required String transcriptId,
    required int segmentId,
    String? content,
    String? speakerLabel,
  });

  // Speakers management
  Future<List<RecordingSpeakerModel>> getSpeakers(String recordingId);
  Future<RecordingSpeakerModel> updateSpeaker({
    required String recordingId,
    required String speakerLabel,
    String? displayName,
    String? color,
  });
}

class TranscriptionRemoteDataSourceImpl
    implements TranscriptionRemoteDataSource {
  final Dio dio;
  final SupabaseClient supabaseClient;

  TranscriptionRemoteDataSourceImpl({
    required this.dio,
    required this.supabaseClient,
  });

  @override
  Future<AudioUploadResponseModel> uploadAudio(File audioFile) async {
    try {
      // Read file bytes
      final fileBytes = await audioFile.readAsBytes();
      final fileSizeBytes = fileBytes.length;
      final fileSizeMb = fileSizeBytes / (1024 * 1024);

      // Get original file name
      final originalFileName = audioFile.path.split('/').last;
      final extension = originalFileName.split('.').last.toLowerCase();

      // Generate unique file name
      final fileName = SupabaseConfig.generateFileName(originalFileName);

      const userId = 'user_001'; 

      // Generate storage path
      final storagePath = SupabaseConfig.transcriptionPath(userId, fileName);

      // Determine content type
      final contentType = _getContentType(extension);

      // Upload to Supabase Storage
      final publicUrl = await supabaseClient.uploadFile(
        bucket: SupabaseConfig.audioBucket,
        path: storagePath,
        fileBytes: fileBytes,
        contentType: contentType,
        metadata: {'original_filename': originalFileName, 'user_id': userId},
      );

      return AudioUploadResponseModel(
        message: 'Audio file uploaded successfully',
        audioFile: AudioFileModel(
          filename: fileName,
          originalFilename: originalFileName,
          fileSize: fileSizeBytes,
          duration: 0.0, // Duration would need to be calculated or fetched
          format: extension,
          id: 0, 
          userId: 0, 
          filePath: publicUrl,
          status: 'uploaded',
          transcription: null,
          confidenceScore: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        uploadInfo: UploadInfoModel(
          fileSizeMb: fileSizeMb,
          format: extension,
          durationSeconds: 0.0, // Duration would need to be calculated
          status: 'uploaded',
        ),
      );
    } catch (e) {
      throw Exception('Failed to upload audio file: $e');
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
  Future<TranscriptionResponseModel> transcribeAudio(
    TranscriptionRequestModel request,
  ) async {
    try {
      final response = await dio.post(
        '/transcript/transcribe',
        data: request.toJson(),
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      if (response.statusCode == 200) {
        return TranscriptionResponseModel.fromJson(response.data);
      } else {
        throw Exception('Failed to transcribe audio');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }

  @override
  Future<TranscriptionResponseModel> transcribeRecording(
    String recordingId,
  ) async {
    try {
      final url =
          '${AppConstants.recordingsEndpoint.replaceAll(RegExp(r'/$'), '')}/$recordingId/transcribe';

      if (kDebugMode) {
        debugPrint('Transcribing recording: POST $url');
      }

      final response = await dio.post(url);

   
      if (response.statusCode == 202) {

        return TranscriptionResponseModel(
          audioId: 0, // Not applicable for recording-based transcription
          transcript: '',
          confidence: 0.0,
          languageCode: 'en',
          segments: [],
          wordCount: 0,
          status: 'processing',
          processedAt: DateTime.now(),
        );
      } else {
        throw Exception(
          'Failed to transcribe recording: unexpected status ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }

  @override
  Future<List<TranscriptModel>> getTranscripts({
    required String recordingId,
    bool? latest,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (latest != null) queryParams['latest'] = latest;

      final response = await dio.get(
        '${AppConstants.recordingsEndpoint.replaceAll(RegExp(r'/$'), '')}/$recordingId/transcripts',
        queryParameters: queryParams,
      );
      if (response.statusCode == 200) {
        return (response.data as List)
            .map((json) => TranscriptModel.fromJson(json))
            .toList();
      } else {
        throw Exception('Failed to get transcripts');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }

  @override
  Future<Map<String, dynamic>> getTranscriptDetail(String transcriptId) async {
    try {
      // Remove trailing slash from transcriptsEndpoint if present
      final endpoint = AppConstants.transcriptsEndpoint.replaceAll(
        RegExp(r'/$'),
        '',
      );
      final url = '$endpoint/$transcriptId';

      if (kDebugMode) {
        debugPrint('Getting transcript detail: GET $url');
      }

      final response = await dio.get(url);
      if (response.statusCode == 200) {
        // Response is TranscriptDetail which has transcript fields at top level + segments array
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to get transcript detail');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }

  @override
  Future<TranscriptModel> updateTranscript({
    required String transcriptId,
    String? language,
    bool? isActive,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (language != null) data['language'] = language;
      if (isActive != null) data['is_active'] = isActive;

      final response = await dio.patch(
        '${AppConstants.transcriptsEndpoint}/$transcriptId',
        data: data,
      );
      if (response.statusCode == 200) {
        return TranscriptModel.fromJson(response.data);
      } else {
        throw Exception('Failed to update transcript');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }

  @override
  Future<TranscriptSegmentModel> updateSegment({
    required String transcriptId,
    required int segmentId,
    String? content,
    String? speakerLabel,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (content != null) data['content'] = content;
      if (speakerLabel != null) data['speaker_label'] = speakerLabel;

      final response = await dio.patch(
        '${AppConstants.transcriptsEndpoint}/$transcriptId/segments/$segmentId',
        data: data,
      );
      if (response.statusCode == 200) {
        return TranscriptSegmentModel.fromJson(response.data);
      } else {
        throw Exception('Failed to update segment');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }

  @override
  Future<List<RecordingSpeakerModel>> getSpeakers(String recordingId) async {
    try {
      final response = await dio.get(
        '${AppConstants.recordingsEndpoint.replaceAll(RegExp(r'/$'), '')}/$recordingId/speakers',
      );
      if (response.statusCode == 200) {
        return (response.data as List)
            .map((json) => RecordingSpeakerModel.fromJson(json))
            .toList();
      } else {
        throw Exception('Failed to get speakers');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }

  @override
  Future<RecordingSpeakerModel> updateSpeaker({
    required String recordingId,
    required String speakerLabel,
    String? displayName,
    String? color,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (displayName != null) data['display_name'] = displayName;
      if (color != null) data['color'] = color;

      final response = await dio.patch(
        '${AppConstants.recordingsEndpoint.replaceAll(RegExp(r'/$'), '')}/$recordingId/speakers/$speakerLabel',
        data: data,
      );
      if (response.statusCode == 200) {
        return RecordingSpeakerModel.fromJson(response.data);
      } else {
        throw Exception('Failed to update speaker');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }
}
