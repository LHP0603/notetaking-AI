import 'package:equatable/equatable.dart';

class ExportJob extends Equatable {
  final String exportId;
  final String userId;
  final String recordingId;
  final String exportType;
  final String status;
  final String? filePath;
  final String? downloadUrl;
  final DateTime? createdAt;
  final DateTime? completedAt;

  const ExportJob({
    required this.exportId,
    required this.userId,
    required this.recordingId,
    required this.exportType,
    required this.status,
    this.filePath,
    this.downloadUrl,
    this.createdAt,
    this.completedAt,
  });

  @override
  List<Object?> get props => [
    exportId,
    userId,
    recordingId,
    exportType,
    status,
    filePath,
    downloadUrl,
    createdAt,
    completedAt,
  ];
}
