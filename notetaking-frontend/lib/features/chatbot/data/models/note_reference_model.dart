import '../../domain/entities/note_reference.dart';

class NoteReferenceModel extends NoteReference {
  const NoteReferenceModel({
    required super.noteId,
    required super.title,
  });

  factory NoteReferenceModel.fromJson(Map<String, dynamic> json) {
    int _intFrom(dynamic value) {
      if (value is int) {
        return value;
      }
      if (value is num) {
        return value.toInt();
      }
      if (value is String) {
        return int.tryParse(value) ?? 0;
      }
      return 0;
    }

    return NoteReferenceModel(
      noteId: _intFrom(json['note_id']),
      title: json['title']?.toString() ?? '',
    );
  }
}
