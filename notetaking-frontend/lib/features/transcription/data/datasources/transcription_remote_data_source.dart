import 'dart:io';
import 'package:dio/dio.dart';
import '../models/audio_upload_response.dart';
import '../models/transcription_models.dart';

abstract class TranscriptionRemoteDataSource {
  Future<AudioUploadResponse> uploadAudio(File audioFile);
  Future<TranscriptionResponse> transcribeAudio(TranscriptionRequest request);
}

class TranscriptionRemoteDataSourceImpl implements TranscriptionRemoteDataSource {
  final Dio dio;

  TranscriptionRemoteDataSourceImpl({required this.dio});

  @override
  Future<AudioUploadResponse> uploadAudio(File audioFile) async {
    try {
      // Create FormData for multipart upload
      FormData formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          audioFile.path,
          filename: audioFile.path.split('/').last,
        ),
      });

      final response = await dio.post(
        '/audio/upload',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      if (response.statusCode == 200) {
        return AudioUploadResponse.fromJson(response.data);
      } else {
        throw Exception('Failed to upload audio file');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }

  @override
  Future<TranscriptionResponse> transcribeAudio(TranscriptionRequest request) async {
    try {
      final response = await dio.post(
        '/transcript/transcribe',
        data: request.toJson(),
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        return TranscriptionResponse.fromJson(response.data);
      } else {
        throw Exception('Failed to transcribe audio');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }
}