import 'package:equatable/equatable.dart';

class Folder extends Equatable {
  final String folderId; 
  final String userId; 
  final String name;
  final String? parentFolderId; 
  final bool isDeleted;
  final DateTime? deletedAt; 
  final DateTime createdAt;

  const Folder({
    required this.folderId,
    required this.userId,
    required this.name,
    this.parentFolderId,
    required this.isDeleted,
    this.deletedAt,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        folderId,
        userId,
        name,
        parentFolderId,
        isDeleted,
        deletedAt,
        createdAt,
      ];
}


