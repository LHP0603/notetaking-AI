import 'package:dio/dio.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/summary_model.dart';

abstract class SummaryRemoteDataSource {
  // Legacy methods
  Future<SummaryModel> getSummary(String transcriptionId);
  Future<SummaryModel> saveSummary(SummaryModel summary);
  Future<SummaryModel> resummarize(String transcriptionId);
  Future<SummaryModel> updateActionItem(
    String summaryId,
    String actionItemId,
    bool isCompleted,
  );

  // Recording-based summary methods (new API)
  Future<SummaryModel> summarizeRecording({
    required String recordingId,
    String? summaryStyle,
  });
  Future<List<SummaryModel>> getSummaries({
    required String recordingId,
    bool? latest,
  });
  Future<SummaryModel> getSummaryDetail(String summaryId);
  Future<SummaryModel> updateSummary({
    required String summaryId,
    Map<String, dynamic>? contentStructure,
    String? type,
    bool? isLatest,
  });

  /// Generate summary for a recording - POST /recordings/{id}/summarize
  Future<void> generateSummary(
    String recordingId, {
    String summaryStyle = 'MEETING',
  });

  /// Fetch latest summary ID for a recording - GET /recordings/{id}/summaries?latest=true
  Future<String?> fetchLatestSummaryId(String recordingId);

  /// Fetch summary content by ID - GET /summaries/{id}
  Future<SummaryModel> fetchSummary(String summaryId);
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

  @override
  Future<SummaryModel> summarizeRecording({
    required String recordingId,
    String? summaryStyle,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (summaryStyle != null) data['summary_style'] = summaryStyle;

      final response = await dio.post(
        '${AppConstants.recordingsEndpoint.replaceAll(RegExp(r'/$'), '')}/$recordingId/summarize',
        data: data,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return SummaryModel.fromJson(response.data);
      } else {
        throw Exception('Failed to summarize recording');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }

  @override
  Future<List<SummaryModel>> getSummaries({
    required String recordingId,
    bool? latest,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (latest != null) queryParams['latest'] = latest;

      final response = await dio.get(
        '${AppConstants.recordingsEndpoint.replaceAll(RegExp(r'/$'), '')}/$recordingId/summaries',
        queryParameters: queryParams,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        return (response.data as List)
            .map((json) => SummaryModel.fromJson(json))
            .toList();
      } else {
        throw Exception('Failed to get summaries');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }

  @override
  Future<SummaryModel> getSummaryDetail(String summaryId) async {
    try {
      final response = await dio.get(
        '${AppConstants.summariesEndpoint}/$summaryId',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        return SummaryModel.fromJson(response.data);
      } else {
        throw Exception('Failed to get summary detail');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }

  @override
  Future<SummaryModel> updateSummary({
    required String summaryId,
    Map<String, dynamic>? contentStructure,
    String? type,
    bool? isLatest,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (contentStructure != null) data['content_structure'] = contentStructure;
      if (type != null) data['type'] = type;
      if (isLatest != null) data['is_latest'] = isLatest;

      final response = await dio.patch(
        '${AppConstants.summariesEndpoint}/$summaryId',
        data: data,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        return SummaryModel.fromJson(response.data);
      } else {
        throw Exception('Failed to update summary');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }

  @override
  Future<void> generateSummary(
    String recordingId, {
    String summaryStyle = 'MEETING',
  }) async {
    try {
      final url =
          '${AppConstants.recordingsEndpoint.replaceAll(RegExp(r'/$'), '')}/$recordingId/summarize';

      final response = await dio.post(
        url,
        data: {'summary_style': summaryStyle},
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      // Accept 200, 201, or 202 (async processing)
      if (response.statusCode != 200 &&
          response.statusCode != 201 &&
          response.statusCode != 202) {
        throw Exception(
          'Failed to generate summary: unexpected status ${response.statusCode}',
        );
      }
      // Return void on success
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }

  @override
  Future<String?> fetchLatestSummaryId(String recordingId) async {
    try {
      final url =
          '${AppConstants.recordingsEndpoint.replaceAll(RegExp(r'/$'), '')}/$recordingId/summaries';

      final response = await dio.get(
        url,
        queryParameters: {'latest': true},
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final summaries = response.data as List<dynamic>;
        if (summaries.isEmpty) {
          return null;
        }
        // Return the first summary's id
        final firstSummary = summaries.first as Map<String, dynamic>;
        return firstSummary['id'] as String? ??
            firstSummary['summary_id'] as String?;
      } else {
        throw Exception('Failed to fetch latest summary ID: ${response.statusCode}');
      }
    } on DioException catch (e) {
      // Handle 401 specifically - token might need refresh
      if (e.response?.statusCode == 401) {
        throw Exception('Authentication failed. Please try again.');
      }
      // Handle 404 - no summaries exist yet (not an error)
      if (e.response?.statusCode == 404) {
        return null;
      }
      throw Exception('Network error: ${e.message}');
    }
  }

  @override
  Future<SummaryModel> fetchSummary(String summaryId) async {
    try {
      final url =
          '${AppConstants.summariesEndpoint.replaceAll(RegExp(r'/$'), '')}/$summaryId';

      final response = await dio.get(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        return SummaryModel.fromJson(response.data);
      } else {
        throw Exception('Failed to fetch summary');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }
}

