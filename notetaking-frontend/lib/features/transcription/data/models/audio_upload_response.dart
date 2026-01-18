class AudioUploadResponse {
  final String message;
  final AudioFile audioFile;
  final UploadInfo uploadInfo;

  AudioUploadResponse({
    required this.message,
    required this.audioFile,
    required this.uploadInfo,
  });

  factory AudioUploadResponse.fromJson(Map<String, dynamic> json) {
    return AudioUploadResponse(
      message: json['message'],
      audioFile: AudioFile.fromJson(json['audio_file']),
      uploadInfo: UploadInfo.fromJson(json['upload_info']),
    );
  }
}

class AudioFile {
  final String filename;
  final String originalFilename;
  final int fileSize;
  final double duration;
  final String format;
  final int id;
  final int userId;
  final String filePath;
  final String status;
  final String? transcription;
  final double? confidenceScore;
  final DateTime createdAt;
  final DateTime updatedAt;

  AudioFile({
    required this.filename,
    required this.originalFilename,
    required this.fileSize,
    required this.duration,
    required this.format,
    required this.id,
    required this.userId,
    required this.filePath,
    required this.status,
    this.transcription,
    this.confidenceScore,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AudioFile.fromJson(Map<String, dynamic> json) {
    return AudioFile(
      filename: json['filename'],
      originalFilename: json['original_filename'],
      fileSize: json['file_size'],
      duration: json['duration'].toDouble(),
      format: json['format'],
      id: json['id'],
      userId: json['user_id'],
      filePath: json['file_path'],
      status: json['status'],
      transcription: json['transcription'],
      confidenceScore: json['confidence_score']?.toDouble(),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

class UploadInfo {
  final double fileSizeMb;
  final String format;
  final double durationSeconds;
  final String status;

  UploadInfo({
    required this.fileSizeMb,
    required this.format,
    required this.durationSeconds,
    required this.status,
  });

  factory UploadInfo.fromJson(Map<String, dynamic> json) {
    return UploadInfo(
      fileSizeMb: json['file_size_mb'].toDouble(),
      format: json['format'],
      durationSeconds: json['duration_seconds'].toDouble(),
      status: json['status'],
    );
  }
}