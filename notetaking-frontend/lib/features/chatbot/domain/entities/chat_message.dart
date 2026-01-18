import 'package:equatable/equatable.dart';
import 'audio_reference.dart';
import 'note_reference.dart';

class ChatMessage extends Equatable {
  final String messageId;
  final String role;
  final String content;
  final String? intent;
  final List<AudioReference>? audioReferences;
  final List<NoteReference>? noteReferences;
  final List<String>? suggestedQuestions;
  final DateTime createdAt;

  const ChatMessage({
    required this.messageId,
    required this.role,
    required this.content,
    this.intent,
    this.audioReferences,
    this.noteReferences,
    this.suggestedQuestions,
    required this.createdAt,
  });

  bool get isUser => role.toLowerCase() == 'user';
  bool get isAssistant => role.toLowerCase() == 'assistant';
  bool get hasReferences =>
      (audioReferences?.isNotEmpty ?? false) ||
      (noteReferences?.isNotEmpty ?? false);
  bool get hasSuggestions => suggestedQuestions?.isNotEmpty ?? false;

  @override
  List<Object?> get props => [
        messageId,
        role,
        content,
        intent,
        audioReferences,
        noteReferences,
        suggestedQuestions,
        createdAt,
      ];
}
