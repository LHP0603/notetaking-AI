import 'package:equatable/equatable.dart';
import 'action_item.dart';

class Summary extends Equatable {
  final String? id;
  final String? meetingTitle;
  final String executiveSummary;
  final List<String> keyTakeaways;
  final List<ActionItem> actionItems;
  final List<String> tags;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Summary({
    this.id,
    this.meetingTitle,
    required this.executiveSummary,
    required this.keyTakeaways,
    required this.actionItems,
    required this.tags,
    this.createdAt,
    this.updatedAt,
  });

  Summary copyWith({
    String? id,
    String? meetingTitle,
    String? executiveSummary,
    List<String>? keyTakeaways,
    List<ActionItem>? actionItems,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Summary(
      id: id ?? this.id,
      meetingTitle: meetingTitle ?? this.meetingTitle,
      executiveSummary: executiveSummary ?? this.executiveSummary,
      keyTakeaways: keyTakeaways ?? this.keyTakeaways,
      actionItems: actionItems ?? this.actionItems,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        meetingTitle,
        executiveSummary,
        keyTakeaways,
        actionItems,
        tags,
        createdAt,
        updatedAt,
      ];
}

