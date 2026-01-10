import 'package:dio/dio.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/export_job_model.dart';

abstract class ExportRemoteDataSource {
  Future<ExportJobModel> createExportJob({
    required String recordingId,
    required String exportType,
  });
  Future<ExportJobModel> getExportJobStatus(int jobId);
}

class ExportRemoteDataSourceImpl implements ExportRemoteDataSource {
  final Dio dio;

  ExportRemoteDataSourceImpl({required this.dio});

  @override
  Future<ExportJobModel> createExportJob({
    required String recordingId,
    required String exportType,
  }) async {
    try {
      final response = await dio.post(
        '${AppConstants.recordingsEndpoint.replaceAll(RegExp(r'/$'), '')}/$recordingId/export',
        data: {'export_type': exportType},
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return ExportJobModel.fromJson(response.data);
      } else {
        throw Exception('Failed to create export job');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }

  @override
  Future<ExportJobModel> getExportJobStatus(int jobId) async {
    try {
      final response = await dio.get('${AppConstants.exportJobsEndpoint}/$jobId');
      if (response.statusCode == 200) {
        return ExportJobModel.fromJson(response.data);
      } else {
        throw Exception('Failed to get export job status');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }
}

