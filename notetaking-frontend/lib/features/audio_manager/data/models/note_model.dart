import 'dart:convert';
import '../../domain/entities/note.dart';

class NoteModel extends Note {
  const NoteModel({
    required super.id,
    required super.title,
    required super.content,
    super.summary,
    required super.category,
    required super.priority,
    required super.isFavorite,
    required super.color,
    super.tags,
    required super.audioFileId,
    required super.createdAt,
    required super.updatedAt,
  });

  factory NoteModel.fromJson(Map<String, dynamic> json) {
    int? _intFrom(dynamic value) {
      if (value is int) {
        return value;
      }
      if (value is num) {
        return value.toInt();
      }
      if (value is String) {
        return int.tryParse(value);
      }
      return null;
    }

    bool _boolFrom(dynamic value) {
      if (value is bool) {
        return value;
      }
      if (value is String) {
        return value.toLowerCase() == 'true';
      }
      if (value is num) {
        return value != 0;
      }
      return false;
    }

    String _stringFrom(dynamic value) {
      return value?.toString() ?? '';
    }

    String? _summaryFrom(dynamic value) {
      if (value == null) {
        return null;
      }
      if (value is String) {
        return value;
      }
      if (value is Map || value is List) {
        return jsonEncode(value);
      }
      return value.toString();
    }

    DateTime _dateFrom(dynamic value) {
      if (value is DateTime) {
        return value;
      }
      return DateTime.parse(value.toString());
    }

    return NoteModel(
      id: _intFrom(json['id']) ?? 0,
      title: _stringFrom(json['title']),
      content: _stringFrom(json['content']),
      summary: _summaryFrom(json['summary']),
      category: _stringFrom(json['category']),
      priority: _stringFrom(json['priority']),
      isFavorite: _boolFrom(json['is_favorite']),
      color: _stringFrom(json['color']),
      tags: json['tags']?.toString(),
      audioFileId: _intFrom(json['audio_file_id']) ?? 0,
      createdAt: _dateFrom(json['created_at']),
      updatedAt: _dateFrom(json['updated_at']),
    );
  }
}
