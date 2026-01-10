import 'package:equatable/equatable.dart';
import 'audio_file.dart';
import 'upload_info.dart';

class AudioUploadResponse extends Equatable {
  final String message;
  final AudioFile audioFile;
  final UploadInfo uploadInfo;

  const AudioUploadResponse({
    required this.message,
    required this.audioFile,
    required this.uploadInfo,
  });

  @override
  List<Object?> get props => [message, audioFile, uploadInfo];
}
