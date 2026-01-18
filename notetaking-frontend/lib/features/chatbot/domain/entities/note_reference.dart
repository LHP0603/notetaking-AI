import 'package:equatable/equatable.dart';

class NoteReference extends Equatable {
  final int noteId;
  final String title;

  const NoteReference({
    required this.noteId,
    required this.title,
  });

  @override
  List<Object?> get props => [noteId, title];
}
