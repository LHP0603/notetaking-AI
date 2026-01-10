import '../../domain/entities/action_item.dart';

class ActionItemModel extends ActionItem {
  const ActionItemModel({
    required super.id,
    required super.text,
    required super.assignedToId,
    required super.assignedToName,
    required super.assignedToInitials,
    required super.assignedToColorValue,
    super.isCompleted,
  });

  factory ActionItemModel.fromJson(Map<String, dynamic> json) {
    return ActionItemModel(
      id: json['id'].toString(),
      text: json['text'] as String,
      assignedToId: json['assigned_to_id']?.toString() ?? '',
      assignedToName: json['assigned_to_name'] as String? ?? '',
      assignedToInitials: json['assigned_to_initials'] as String? ?? '',
      assignedToColorValue: json['assigned_to_color'] as int? ?? 0xFF3B82F6,
      isCompleted: json['is_completed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'assigned_to_id': assignedToId,
      'assigned_to_name': assignedToName,
      'assigned_to_initials': assignedToInitials,
      'assigned_to_color': assignedToColorValue,
      'is_completed': isCompleted,
    };
  }

  factory ActionItemModel.fromEntity(ActionItem entity) {
    return ActionItemModel(
      id: entity.id,
      text: entity.text,
      assignedToId: entity.assignedToId,
      assignedToName: entity.assignedToName,
      assignedToInitials: entity.assignedToInitials,
      assignedToColorValue: entity.assignedToColorValue,
      isCompleted: entity.isCompleted,
    );
  }
}

