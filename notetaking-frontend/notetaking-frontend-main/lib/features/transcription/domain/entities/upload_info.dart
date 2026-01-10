import 'package:equatable/equatable.dart';

class UploadInfo extends Equatable {
  final double fileSizeMb;
  final String format;
  final double durationSeconds;
  final String status;

  const UploadInfo({
    required this.fileSizeMb,
    required this.format,
    required this.durationSeconds,
    required this.status,
  });

  @override
  List<Object?> get props => [fileSizeMb, format, durationSeconds, status];
}
