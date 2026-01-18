import '../../domain/entities/chat_message.dart';
import '../../domain/entities/audio_reference.dart';
import '../../domain/entities/note_reference.dart';
import 'audio_reference_model.dart';
import 'note_reference_model.dart';

class ChatMessageModel extends ChatMessage {
  const ChatMessageModel({
    required super.messageId,
    required super.role,
    required super.content,
    super.intent,
    super.audioReferences,
    super.noteReferences,
    super.suggestedQuestions,
    required super.createdAt,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    final audioReferences = _parseAudioReferences(json['audio_references']);
    final noteReferences = _parseNoteReferences(json['note_references']);
    final suggestions = _parseSuggestions(json['suggested_questions']);

    final roleValue = json['role']?.toString();

    final contentValue =
        json['response']?.toString() ?? json['content']?.toString() ?? '';

    return ChatMessageModel(
      messageId: json['message_id']?.toString() ?? '',
      role: roleValue?.toLowerCase() ?? 'assistant',
      content: contentValue,
      intent: json['intent']?.toString(),
      audioReferences: audioReferences,
      noteReferences: noteReferences,
      suggestedQuestions: suggestions,
      createdAt: _parseDate(json['created_at']) ?? DateTime.now(),
    );
  }

  factory ChatMessageModel.fromJobResult(Map<String, dynamic> result) {
    return ChatMessageModel(
      messageId: result['message_id']?.toString() ?? '',
      role: 'assistant',
      content: result['response']?.toString() ?? '',
      intent: result['intent']?.toString(),
      audioReferences: _parseAudioReferences(result['audio_references']),
      noteReferences: _parseNoteReferences(result['note_references']),
      suggestedQuestions: _parseSuggestions(result['suggested_questions']),
      createdAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message_id': messageId,
      'role': role,
      'response': content,
      'intent': intent,
      'audio_references':
          audioReferences
              ?.map(
                (ref) => {
                  'audio_id': ref.audioId,
                  'title': ref.title,
                  'duration': ref.duration,
                  'created_at': ref.createdAt.toIso8601String(),
                },
              )
              .toList(),
      'note_references':
          noteReferences
              ?.map(
                (ref) => {
                  'note_id': ref.noteId,
                  'title': ref.title,
                },
              )
              .toList(),
      'suggested_questions': suggestedQuestions,
      'created_at': createdAt.toIso8601String(),
    };
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is String) {
      return DateTime.tryParse(value);
    }
    if (value is DateTime) {
      return value;
    }
    return null;
  }

  static List<AudioReference>? _parseAudioReferences(dynamic value) {
    if (value is! List) {
      return null;
    }
    return value
        .map(
          (item) =>
              AudioReferenceModel.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  static List<NoteReference>? _parseNoteReferences(dynamic value) {
    if (value is! List) {
      return null;
    }
    return value
        .map(
          (item) => NoteReferenceModel.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  static List<String>? _parseSuggestions(dynamic value) {
    if (value is! List) {
      return null;
    }
    return value.map((item) => item.toString()).toList();
  }
}
