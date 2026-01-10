import '../../domain/entities/folder.dart';

class FolderModel extends Folder {
  const FolderModel({
    required String folderId,
    required String userId,
    required String name,
    String? parentFolderId,
    required bool isDeleted,
    DateTime? deletedAt,
    required DateTime createdAt,
  }) : super(
          folderId: folderId,
          userId: userId,
          name: name,
          parentFolderId: parentFolderId,
          isDeleted: isDeleted,
          deletedAt: deletedAt,
          createdAt: createdAt,
        );

  factory FolderModel.fromJson(Map<String, dynamic> json) {
    return FolderModel(
      folderId: json['folder_id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      parentFolderId: json['parent_folder_id'] as String?,
      isDeleted: json['is_deleted'] as bool? ?? false,
      deletedAt:
          json['deleted_at'] != null
              ? DateTime.parse(json['deleted_at'] as String)
              : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'folder_id': folderId,
      'user_id': userId,
      'name': name,
      'parent_folder_id': parentFolderId,
      'is_deleted': isDeleted,
      'deleted_at': deletedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}


