import 'package:dio/dio.dart';
import '../models/summary_model.dart';

abstract class SummaryRemoteDataSource {
  Future<SummaryModel> getSummary(String transcriptionId);
  Future<SummaryModel> saveSummary(SummaryModel summary);
  Future<SummaryModel> resummarize(String transcriptionId);
  Future<SummaryModel> updateActionItem(
    String summaryId,
    String actionItemId,
    bool isCompleted,
  );
}

class SummaryRemoteDataSourceImpl implements SummaryRemoteDataSource {
  final Dio dio;

  SummaryRemoteDataSourceImpl({required this.dio});

  @override
  Future<SummaryModel> getSummary(String transcriptionId) async {
    try {
      final response = await dio.get(
        '/summary/$transcriptionId',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        return SummaryModel.fromJson(response.data);
      } else {
        throw Exception('Failed to get summary');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }

  @override
  Future<SummaryModel> saveSummary(SummaryModel summary) async {
    try {
      final response = await dio.post(
        '/summary',
        data: summary.toJson(),
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return SummaryModel.fromJson(response.data);
      } else {
        throw Exception('Failed to save summary');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }

  @override
  Future<SummaryModel> resummarize(String transcriptionId) async {
    try {
      final response = await dio.post(
        '/summary/resummarize',
        data: {'transcription_id': transcriptionId},
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        return SummaryModel.fromJson(response.data);
      } else {
        throw Exception('Failed to resummarize');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }

  @override
  Future<SummaryModel> updateActionItem(
    String summaryId,
    String actionItemId,
    bool isCompleted,
  ) async {
    try {
      final response = await dio.patch(
        '/summary/$summaryId/action-items/$actionItemId',
        data: {'is_completed': isCompleted},
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        return SummaryModel.fromJson(response.data);
      } else {
        throw Exception('Failed to update action item');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }
}

