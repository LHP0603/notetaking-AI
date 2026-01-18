import 'package:dio/dio.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/chat_job_status_model.dart';
import '../models/chat_message_model.dart';
import '../models/chat_session_model.dart';

abstract class ChatbotRemoteDataSource {
  Future<ChatSessionModel> createChatSession({String? title});
  Future<String> sendMessageAsync({
    required String sessionId,
    required String message,
  });
  Future<ChatJobStatusModel> getJobStatus(String jobId);
  Future<List<ChatMessageModel>> getChatHistory({
    required String sessionId,
    int limit = 20,
    int offset = 0,
  });
}

class ChatbotRemoteDataSourceImpl implements ChatbotRemoteDataSource {
  final Dio dio;

  ChatbotRemoteDataSourceImpl({required this.dio});

  @override
  Future<ChatSessionModel> createChatSession({String? title}) async {
    try {
      final trimmedTitle = title?.trim();
      final response = await dio.post(
        AppConstants.chatbotSessionsEndpoint,
        data: trimmedTitle == null || trimmedTitle.isEmpty
            ? null
            : {'title': trimmedTitle},
      );

      final data = _extractData(
        response,
        fallbackMessage: 'Failed to create chat session',
      );

      if (data is Map<String, dynamic>) {
        return ChatSessionModel.fromJson(data);
      }

      throw const ServerException('Invalid response data');
    } on DioException catch (e) {
      throw _handleDioException(
        e,
        fallbackMessage: 'Failed to create chat session',
      );
    }
  }

  @override
  Future<String> sendMessageAsync({
    required String sessionId,
    required String message,
  }) async {
    try {
      final response = await dio.post(
        AppConstants.chatbotMessagesAsync(sessionId),
        data: {'message': message},
      );

      final data = _extractData(
        response,
        fallbackMessage: 'Failed to send message',
      );

      if (data is Map<String, dynamic>) {
        final jobId = data['job_id']?.toString();
        if (jobId != null && jobId.isNotEmpty) {
          return jobId;
        }
      }

      throw const ServerException('Invalid job response');
    } on DioException catch (e) {
      throw _handleDioException(e, fallbackMessage: 'Failed to send message');
    }
  }

  @override
  Future<ChatJobStatusModel> getJobStatus(String jobId) async {
    try {
      final response = await dio.get(AppConstants.taskJobStatus(jobId));

      final data = _extractData(
        response,
        fallbackMessage: 'Failed to fetch job status',
      );

      if (data is Map<String, dynamic>) {
        return ChatJobStatusModel.fromJson(data);
      }

      throw const ServerException('Invalid job status response');
    } on DioException catch (e) {
      throw _handleDioException(
        e,
        fallbackMessage: 'Failed to fetch job status',
      );
    }
  }

  @override
  Future<List<ChatMessageModel>> getChatHistory({
    required String sessionId,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await dio.get(
        AppConstants.chatbotMessages(sessionId),
        queryParameters: {'limit': limit, 'offset': offset},
      );

      final data = _extractData(
        response,
        fallbackMessage: 'Failed to load chat history',
      );

      if (data is! Map<String, dynamic>) {
        throw const ServerException('Invalid history data');
      }

      final messages = data['messages'];
      if (messages == null) {
        return [];
      }
      if (messages is! List) {
        throw const ServerException('Invalid history data');
      }

      return messages
          .map(
            (item) => ChatMessageModel.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList();
    } on DioException catch (e) {
      throw _handleDioException(
        e,
        fallbackMessage: 'Failed to load chat history',
      );
    }
  }

  dynamic _extractData(
    Response<dynamic> response, {
    required String fallbackMessage,
  }) {
    final payload = response.data;
    if (payload is! Map<String, dynamic>) {
      throw const ServerException('Invalid response format');
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
