import 'package:equatable/equatable.dart';

enum ExportType {
  transcriptPdf('TRANSCRIPT_PDF'),
  transcriptDocx('TRANSCRIPT_DOCX'),
  summaryPdf('SUMMARY_PDF'),
  summaryDocx('SUMMARY_DOCX'),
  zip('ZIP');

  final String value;
  const ExportType(this.value);

  static ExportType fromString(String value) {
    return ExportType.values.firstWhere(
      (type) => type.value == value.toUpperCase(),
      orElse: () => ExportType.transcriptPdf,
    );
  }
}

enum ExportJobStatus {
  pending('PENDING'),
  processing('PROCESSING'),
  done('DONE'),
  failed('FAILED');

  final String value;
  const ExportJobStatus(this.value);

  static ExportJobStatus fromString(String value) {
    return ExportJobStatus.values.firstWhere(
      (status) => status.value == value.toUpperCase(),
      orElse: () => ExportJobStatus.pending,
    );
  }
}

class ExportJob extends Equatable {
  final int jobId; // PK
  final String userId; // FK to USERS
  final String recordingId; // FK to RECORDINGS
  final ExportType exportType;
  final ExportJobStatus status;
  final String? filePath; // Path to exported file in Storage
  final String? errorMessage; // Error message if failed
  final DateTime createdAt;
  final DateTime? completedAt;

  const ExportJob({
    required this.jobId,
    required this.userId,
    required this.recordingId,
    required this.exportType,
    required this.status,
    this.filePath,
    this.errorMessage,
    required this.createdAt,
    this.completedAt,
  });

  @override
  List<Object?> get props => [
    jobId,
    userId,
    recordingId,
    exportType,
    status,
    filePath,
    errorMessage,
    createdAt,
    completedAt,
  ];
}
