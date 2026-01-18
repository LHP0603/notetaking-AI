import 'package:equatable/equatable.dart';

class ChatSession extends Equatable {
  final String sessionId;
  final String? title;
  final int totalMessages;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ChatSession({
    required this.sessionId,
    this.title,
    required this.totalMessages,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [
        sessionId,
        title,
        totalMessages,
        isActive,
        createdAt,
        updatedAt,
      ];
}
