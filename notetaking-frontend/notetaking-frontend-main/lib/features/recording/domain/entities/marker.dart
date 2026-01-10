import 'package:equatable/equatable.dart';

enum MarkerType {
  important('IMPORTANT'),
  note('NOTE'),
  bookmark('BOOKMARK');

  final String value;
  const MarkerType(this.value);

  static MarkerType fromString(String value) {
    return MarkerType.values.firstWhere(
      (type) => type.value == value.toUpperCase(),
      orElse: () => MarkerType.note,
    );
  }
}

class Marker extends Equatable {
  final int markerId; // PK
  final String recordingId; // FK to RECORDINGS
  final double timeSeconds; // Time position in audio
  final String label; // User-defined label
  final MarkerType type; // Type of marker
  final String? description; // Optional description
  final DateTime createdAt;

  const Marker({
    required this.markerId,
    required this.recordingId,
    required this.timeSeconds,
    required this.label,
    required this.type,
    this.description,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
    markerId,
    recordingId,
    timeSeconds,
    label,
    type,
    description,
    createdAt,
  ];
}

