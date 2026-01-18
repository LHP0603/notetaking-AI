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

      final payload = response.data;
      if (payload is! Map<String, dynamic>) {
        throw const ServerException('Invalid response format');
      }

      final statusCode = response.statusCode ?? 500;
      final success = payload['success'] == true;
      if (statusCode >= 200 && statusCode < 300 && success) {
        final data = payload['data'];
        if (data is Map<String, dynamic>) {
          return UploadJobModel.fromJson(data);
        }
        throw const ServerException('Invalid response data');
      }

      final message = payload['message']?.toString() ?? 'Upload failed';
      final code = payload['code'] is int ? payload['code'] as int : statusCode;
      throw ServerException(message, code: code);
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        final message = data['message']?.toString() ?? 'Network error occurred';
        final code = data['code'] is int
            ? data['code'] as int
            : e.response?.statusCode ?? 500;
        throw ServerException(message, code: code);
      }
      throw ServerException(
        'Network error occurred',
        code: e.response?.statusCode ?? 500,
      );
    }
  }
}
