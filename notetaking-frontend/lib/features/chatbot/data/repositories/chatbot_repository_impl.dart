import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../auth/data/datasources/auth_local_data_source.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/chat_session.dart';
import '../../domain/repositories/chatbot_repository.dart';
import '../datasources/chatbot_local_data_source.dart';
import '../datasources/chatbot_remote_data_source.dart';

class ChatbotRepositoryImpl implements ChatbotRepository {
  final ChatbotRemoteDataSource remoteDataSource;
  final ChatbotLocalDataSource localDataSource;
  final NetworkInfo networkInfo;
  final AuthLocalDataSource authLocalDataSource;

  ChatbotRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
    required this.authLocalDataSource,
  });

  @override
  Future<Either<Failure, ChatSession>> createChatSession({
    String? title,
  }) async {
    final token = await authLocalDataSource.getAccessToken();
    if (token == null) {
      return const Left(UnauthorizedFailure('Please login to start a chat'));
    }

    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }

    try {
      final session = await remoteDataSource.createChatSession(title: title);
      await localDataSource.cacheSessionId(session.sessionId);
      return Right(session);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, ChatMessage>> sendMessage({
    required String sessionId,
    required String message,
  }) async {
    final token = await authLocalDataSource.getAccessToken();
    if (token == null) {
      return const Left(UnauthorizedFailure('Please login to chat'));
    }

    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }

    try {
      final jobId = await remoteDataSource.sendMessageAsync(
        sessionId: sessionId,
        message: message,
      );

      const pollingInterval = Duration(seconds: 2);
      const maxAttempts = 60;

      for (var attempt = 0; attempt < maxAttempts; attempt++) {
        final status = await remoteDataSource.getJobStatus(jobId);
        final normalizedStatus = status.status.toLowerCase();

        if (normalizedStatus == 'completed') {
          final resultMessage = status.message;
          if (resultMessage != null) {
            return Right(resultMessage);
          }
          return const Left(ServerFailure('Chatbot response was empty'));
        }

        if (normalizedStatus == 'failed' ||
            normalizedStatus == 'error' ||
            normalizedStatus == 'cancelled') {
          return const Left(ServerFailure('Chatbot processing failed'));
        }

        await Future.delayed(pollingInterval);
      }

      return const Left(ServerFailure('Chatbot response timed out'));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<ChatMessage>>> getChatHistory({
    required String sessionId,
    int limit = 20,
    int offset = 0,
  }) async {
    final token = await authLocalDataSource.getAccessToken();
    if (token == null) {
      return const Left(UnauthorizedFailure('Please login to load chats'));
    }

    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }

    try {
      final messages = await remoteDataSource.getChatHistory(
        sessionId: sessionId,
        limit: limit,
        offset: offset,
      );
      return Right(messages);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, String?>> getCachedSessionId() async {
    try {
      final sessionId = await localDataSource.getSessionId();
      return Right(sessionId);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> clearCachedSessionId() async {
    try {
      await localDataSource.clearSessionId();
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }
}
