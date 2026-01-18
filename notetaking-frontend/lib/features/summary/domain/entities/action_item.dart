import 'package:equatable/equatable.dart';

class ActionItem extends Equatable {
  final String id;
  final String text;
  final String assignedToId;
  final String assignedToName;
  final String assignedToInitials;
  final int assignedToColorValue; // Store as int for serialization
  final bool isCompleted;

  const ActionItem({
    required this.id,
    required this.text,
    required this.assignedToId,
    required this.assignedToName,
    required this.assignedToInitials,
    required this.assignedToColorValue,
    this.isCompleted = false,
  });

  ActionItem copyWith({
    String? id,
    String? text,
    String? assignedToId,
    String? assignedToName,
    String? assignedToInitials,
    int? assignedToColorValue,
    bool? isCompleted,
  }) {
    return ActionItem(
      id: id ?? this.id,
      text: text ?? this.text,
      assignedToId: assignedToId ?? this.assignedToId,
      assignedToName: assignedToName ?? this.assignedToName,
      assignedToInitials: assignedToInitials ?? this.assignedToInitials,
      assignedToColorValue: assignedToColorValue ?? this.assignedToColorValue,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  @override
  List<Object?> get props => [
        id,
        text,
        assignedToId,
        assignedToName,
        assignedToInitials,
        assignedToColorValue,
        isCompleted,
      ];
}

