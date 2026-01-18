import '../../domain/entities/audio_reference.dart';

class AudioReferenceModel extends AudioReference {
  const AudioReferenceModel({
    required super.audioId,
    required super.title,
    required super.duration,
    required super.createdAt,
  });

  factory AudioReferenceModel.fromJson(Map<String, dynamic> json) {
    int _intFrom(dynamic value) {
      if (value is int) {
        return value;
      }
      if (value is num) {
        return value.toInt();
      }
      if (value is String) {
        return int.tryParse(value) ?? 0;
      }
      return 0;
    }

    double _doubleFrom(dynamic value) {
      if (value is double) {
        return value;
      }
      if (value is num) {
        return value.toDouble();
      }
      if (value is String) {
        return double.tryParse(value) ?? 0;
      }
      return 0;
    }

    DateTime _dateFrom(dynamic value) {
      if (value is DateTime) {
        return value;
      }
      return DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
    }

    return AudioReferenceModel(
      audioId: _intFrom(json['audio_id']),
      title: json['title']?.toString() ?? '',
      duration: _doubleFrom(json['duration']),
      createdAt: _dateFrom(json['created_at']),
    );
  }
}
