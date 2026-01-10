import '../../domain/entities/marker.dart';

class MarkerModel extends Marker {
  const MarkerModel({
    required int markerId,
    required String recordingId,
    required double timeSeconds,
    required String label,
    required MarkerType type,
    String? description,
    required DateTime createdAt,
  }) : super(
         markerId: markerId,
         recordingId: recordingId,
         timeSeconds: timeSeconds,
         label: label,
         type: type,
         description: description,
         createdAt: createdAt,
       );

  factory MarkerModel.fromJson(Map<String, dynamic> json) {
    return MarkerModel(
      markerId: json['marker_id'] as int,
      recordingId: json['recording_id'] as String,
      timeSeconds: (json['time_seconds'] as num).toDouble(),
      label: json['label'] as String,
      type: MarkerType.fromString(json['type'] as String? ?? 'NOTE'),
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'marker_id': markerId,
      'recording_id': recordingId,
      'time_seconds': timeSeconds,
      'label': label,
      'type': type.value,
      'description': description,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory MarkerModel.fromEntity(Marker entity) {
    return MarkerModel(
      markerId: entity.markerId,
      recordingId: entity.recordingId,
      timeSeconds: entity.timeSeconds,
      label: entity.label,
      type: entity.type,
      description: entity.description,
      createdAt: entity.createdAt,
    );
  }
}

