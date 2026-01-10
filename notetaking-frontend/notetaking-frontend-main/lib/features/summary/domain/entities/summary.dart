import 'package:equatable/equatable.dart';
import 'action_item.dart';

enum SummaryType {
  aiGenerated('AI_GENERATED'),
  userEdited('USER_EDITED');

  final String value;
  const SummaryType(this.value);

  static SummaryType fromString(String value) {
    return SummaryType.values.firstWhere(
      (type) => type.value == value.toUpperCase(),
      orElse: () => SummaryType.aiGenerated,
    );
  }
}

class ContentStructure extends Equatable {
  final String overview;
  final List<String> keyPoints;
  final List<ActionItem> actionItems;

  const ContentStructure({
    required this.overview,
    required this.keyPoints,
    required this.actionItems,
  });

  Map<String, dynamic> toJson() {
    return {
      'overview': overview,
      'key_points': keyPoints,
      'action_items':
          actionItems
              .map(
                (item) => {
                  'id': item.id,
                  'text': item.text,
                  'assigned_to_id': item.assignedToId,
                  'assigned_to_name': item.assignedToName,
                  'assigned_to_initials': item.assignedToInitials,
                  'assigned_to_color_value': item.assignedToColorValue,
                  'is_completed': item.isCompleted,
                },
              )
              .toList(),
    };
  }

  factory ContentStructure.fromJson(Map<String, dynamic> json) {
    // Parse key_points
    final keyPoints =
        (json['key_points'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList() ??
        [];

    // Parse action_items - handle both List<String> and List<Map> formats
    List<ActionItem> actionItems = [];
    final actionItemsRaw = json['action_items'] as List<dynamic>?;
    if (actionItemsRaw != null) {
      actionItems =
          actionItemsRaw.map((e) {
            if (e is String) {
              // If it's a String, create a minimal ActionItem
              return ActionItem(
                id: '', // No ID for string format
                text: e,
                assignedToId: '',
                assignedToName: '',
                assignedToInitials: '',
                assignedToColorValue: 0xFF6B7280, // Default grey color
                isCompleted: false,
              );
            } else if (e is Map<String, dynamic>) {
              // If it's a Map, parse as existing ActionItem format
              return ActionItem(
                id: e['id'] as String? ?? '',
                text: e['text'] as String? ?? '',
                assignedToId: e['assigned_to_id'] as String? ?? '',
                assignedToName: e['assigned_to_name'] as String? ?? '',
                assignedToInitials: e['assigned_to_initials'] as String? ?? '',
                assignedToColorValue: e['assigned_to_color_value'] as int? ?? 0,
                isCompleted: e['is_completed'] as bool? ?? false,
              );
            } else {
              // Fallback: try to convert to string
              return ActionItem(
                id: '',
                text: e.toString(),
                assignedToId: '',
                assignedToName: '',
                assignedToInitials: '',
                assignedToColorValue: 0xFF6B7280,
                isCompleted: false,
              );
            }
          }).toList();
    }

    return ContentStructure(
      overview: json['overview'] as String? ?? '',
      keyPoints: keyPoints,
      actionItems: actionItems,
    );
  }

  @override
  List<Object?> get props => [overview, keyPoints, actionItems];
}

class Summary extends Equatable {
  final String summaryId; // uuid summary_id PK
  final String recordingId; // uuid recording_id FK
  final SummaryType type; // Enum: AI_GENERATED, USER_EDITED
  final ContentStructure
  contentStructure; // JSON: {overview, key_points:[], action_items:[]}
  final DateTime createdAt;

  const Summary({
    required this.summaryId,
    required this.recordingId,
    required this.type,
    required this.contentStructure,
    required this.createdAt,
  });

  Summary copyWith({
    String? summaryId,
    String? recordingId,
    SummaryType? type,
    ContentStructure? contentStructure,
    DateTime? createdAt,
  }) {
    return Summary(
      summaryId: summaryId ?? this.summaryId,
      recordingId: recordingId ?? this.recordingId,
      type: type ?? this.type,
      contentStructure: contentStructure ?? this.contentStructure,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Convenience getters for backward compatibility
  String get executiveSummary => contentStructure.overview;
  List<String> get keyTakeaways => contentStructure.keyPoints;
  List<ActionItem> get actionItems => contentStructure.actionItems;

  @override
  List<Object?> get props => [
    summaryId,
    recordingId,
    type,
    contentStructure,
    createdAt,
  ];
}
