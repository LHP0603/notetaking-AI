import 'dart:convert';
import '../../domain/entities/summary.dart';

class SummaryModel extends Summary {
  const SummaryModel({
    required String summaryId,
    required String recordingId,
    required SummaryType type,
    required ContentStructure contentStructure,
    required DateTime createdAt,
  }) : super(
         summaryId: summaryId,
         recordingId: recordingId,
         type: type,
         contentStructure: contentStructure,
         createdAt: createdAt,
       );

  factory SummaryModel.fromJson(Map<String, dynamic> json) {
    // Parse content_structure - can be a JSON string or Map
    ContentStructure contentStructure;
    if (json['content_structure'] is String) {
      // If it's a JSON string, parse it
      final contentJson = jsonDecode(json['content_structure'] as String)
          as Map<String, dynamic>;
      contentStructure = ContentStructure.fromJson(contentJson);
    } else if (json['content_structure'] is Map) {
      // If it's already a Map, use it directly
      contentStructure =
          ContentStructure.fromJson(json['content_structure'] as Map<String, dynamic>);
    } else {
      // Fallback to empty structure
      contentStructure = const ContentStructure(
        overview: '',
        keyPoints: [],
        actionItems: [],
      );
    }

    return SummaryModel(
      summaryId: json['summary_id'] as String,
      recordingId: json['recording_id'] as String,
      type: SummaryType.fromString(json['type'] as String? ?? 'AI_GENERATED'),
      contentStructure: contentStructure,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'summary_id': summaryId,
      'recording_id': recordingId,
      'type': type.value,
      'content_structure': jsonEncode(contentStructure.toJson()),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory SummaryModel.fromEntity(Summary entity) {
    return SummaryModel(
      summaryId: entity.summaryId,
      recordingId: entity.recordingId,
      type: entity.type,
      contentStructure: entity.contentStructure,
      createdAt: entity.createdAt,
    );
  }
}

