import '../../domain/entities/audio_upload_response.dart';
import '../../domain/entities/audio_file.dart';
import '../../domain/entities/upload_info.dart';

// Data models for JSON serialization - extend domain entities
class AudioUploadResponseModel extends AudioUploadResponse {
  const AudioUploadResponseModel({
    required String message,
    required AudioFile audioFile,
    required UploadInfo uploadInfo,
  }) : super(
         message: message,
         audioFile: audioFile,
         uploadInfo: uploadInfo,
       );

  factory AudioUploadResponseModel.fromJson(Map<String, dynamic> json) {
    return AudioUploadResponseModel(
      message: json['message'],
      audioFile: AudioFileModel.fromJson(json['audio_file']),
      uploadInfo: UploadInfoModel.fromJson(json['upload_info']),
    );
  }

  factory AudioUploadResponseModel.fromEntity(AudioUploadResponse entity) {
    return AudioUploadResponseModel(
      message: entity.message,
      audioFile: AudioFileModel.fromEntity(entity.audioFile),
      uploadInfo: UploadInfoModel.fromEntity(entity.uploadInfo),
    );
  }
}

class AudioFileModel extends AudioFile {
  const AudioFileModel({
    required String filename,
    required String originalFilename,
    required int fileSize,
    required double duration,
    required String format,
    required int id,
    required int userId,
    required String filePath,
    required String status,
    String? transcription,
    double? confidenceScore,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super(
         filename: filename,
         originalFilename: originalFilename,
         fileSize: fileSize,
         duration: duration,
         format: format,
         id: id,
         userId: userId,
         filePath: filePath,
         status: status,
         transcription: transcription,
         confidenceScore: confidenceScore,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  factory AudioFileModel.fromJson(Map<String, dynamic> json) {
    return AudioFileModel(
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

  factory AudioFileModel.fromEntity(AudioFile entity) {
    return AudioFileModel(
      filename: entity.filename,
      originalFilename: entity.originalFilename,
      fileSize: entity.fileSize,
      duration: entity.duration,
      format: entity.format,
      id: entity.id,
      userId: entity.userId,
      filePath: entity.filePath,
      status: entity.status,
      transcription: entity.transcription,
      confidenceScore: entity.confidenceScore,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}

class UploadInfoModel extends UploadInfo {
  const UploadInfoModel({
    required double fileSizeMb,
    required String format,
    required double durationSeconds,
    required String status,
  }) : super(
         fileSizeMb: fileSizeMb,
         format: format,
         durationSeconds: durationSeconds,
         status: status,
       );

  factory UploadInfoModel.fromJson(Map<String, dynamic> json) {
    return UploadInfoModel(
      fileSizeMb: json['file_size_mb'].toDouble(),
      format: json['format'],
      durationSeconds: json['duration_seconds'].toDouble(),
      status: json['status'],
    );
  }

  factory UploadInfoModel.fromEntity(UploadInfo entity) {
    return UploadInfoModel(
      fileSizeMb: entity.fileSizeMb,
      format: entity.format,
      durationSeconds: entity.durationSeconds,
      status: entity.status,
    );
  }
}