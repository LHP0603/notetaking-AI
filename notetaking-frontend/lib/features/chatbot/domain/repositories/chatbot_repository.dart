import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/chat_message.dart';
import '../entities/chat_session.dart';

abstract class ChatbotRepository {
  Future<Either<Failure, ChatSession>> createChatSession({String? title});
  Future<Either<Failure, ChatMessage>> sendMessage({
    required String sessionId,
    required String message,
  });
  Future<Either<Failure, List<ChatMessage>>> getChatHistory({
    required String sessionId,
    int limit = 20,
    int offset = 0,
  });
  Future<Either<Failure, String?>> getCachedSessionId();
  Future<Either<Failure, void>> clearCachedSessionId();
}
