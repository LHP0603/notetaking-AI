import '../../domain/entities/summary.dart';
import 'action_item_model.dart';

class SummaryModel extends Summary {
  const SummaryModel({
    super.id,
    super.meetingTitle,
    required super.executiveSummary,
    required super.keyTakeaways,
    required super.actionItems,
    required super.tags,
    super.createdAt,
    super.updatedAt,
  });

  factory SummaryModel.fromJson(Map<String, dynamic> json) {
    return SummaryModel(
      id: json['id']?.toString(),
      meetingTitle: json['meeting_title'] as String?,
      executiveSummary: json['executive_summary'] as String? ?? '',
      keyTakeaways: (json['key_takeaways'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      actionItems: (json['action_items'] as List<dynamic>?)
              ?.map((e) => ActionItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      tags: (json['tags'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (meetingTitle != null) 'meeting_title': meetingTitle,
      'executive_summary': executiveSummary,
      'key_takeaways': keyTakeaways,
      'action_items': actionItems
          .map((item) => ActionItemModel.fromEntity(item).toJson())
          .toList(),
      'tags': tags,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  factory SummaryModel.fromEntity(Summary entity) {
    return SummaryModel(
      id: entity.id,
      meetingTitle: entity.meetingTitle,
      executiveSummary: entity.executiveSummary,
      keyTakeaways: entity.keyTakeaways,
      actionItems: entity.actionItems,
      tags: entity.tags,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}

