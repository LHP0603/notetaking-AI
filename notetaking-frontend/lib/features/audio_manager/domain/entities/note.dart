import 'package:equatable/equatable.dart';

class Note extends Equatable {
  final int id;
  final String title;
  final String content;
  final String? summary;
  final String category;
  final String priority;
  final bool isFavorite;
  final String color;
  final String? tags;
  final int audioFileId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Note({
    required this.id,
    required this.title,
    required this.content,
    this.summary,
    required this.category,
    required this.priority,
    required this.isFavorite,
    required this.color,
    this.tags,
    required this.audioFileId,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
    id,
    title,
    content,
    summary,
    category,
    priority,
    isFavorite,
    color,
    tags,
    audioFileId,
    createdAt,
    updatedAt,
  ];
}
