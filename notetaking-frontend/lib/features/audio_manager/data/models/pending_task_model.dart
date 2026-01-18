import '../../domain/entities/pending_task.dart';

class PendingTaskModel extends PendingTask {
  const PendingTaskModel({
    required super.type,
    required super.id,
    required super.title,
    required super.description,
    super.date,
    super.fileSize,
    super.wordCount,
  });

  factory PendingTaskModel.fromUntranscribedJson(Map<String, dynamic> json) {
    final filename = json['filename'] as String;
    final uploadDate =
        json['upload_date'] != null
            ? DateTime.parse(json['upload_date'] as String)
            : null;
    final fileSize = json['file_size'] as int?;

    return PendingTaskModel(
      type: PendingTaskType.untranscribedAudio,
      id: json['audio_id'] as int,
      title: filename,
      description: _buildAudioDescription(uploadDate, fileSize),
      date: uploadDate,
      fileSize: fileSize,
    );
  }

  factory PendingTaskModel.fromUnsummarizedJson(Map<String, dynamic> json) {
    final filename = json['audio_filename'] as String;
    final transcriptionDate =
        json['transcription_date'] != null
            ? DateTime.parse(json['transcription_date'] as String)
            : null;
    final wordCount = json['word_count'] as int?;

    return PendingTaskModel(
      type: PendingTaskType.unsummarizedTranscript,
      id: json['transcription_id'] as int,
      title: filename,
      description: _buildTranscriptDescription(transcriptionDate, wordCount),
      date: transcriptionDate,
      wordCount: wordCount,
    );
  }

  static String _buildAudioDescription(DateTime? date, int? size) {
    final parts = <String>[];
    if (date != null) {
      parts.add('Uploaded ${_formatDate(date)}');
    }
    if (size != null) {
      parts.add(_formatBytes(size));
    }
    return parts.isEmpty ? 'Ready to transcribe' : parts.join(' • ');
  }

  static String _buildTranscriptDescription(DateTime? date, int? wordCount) {
    final parts = <String>[];
    if (date != null) {
      parts.add('Transcribed ${_formatDate(date)}');
    }
    if (wordCount != null) {
      parts.add('$wordCount words');
    }
    return parts.isEmpty ? 'Ready to summarize' : parts.join(' • ');
  }

  static String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  static String _formatBytes(int bytes) {
    final mb = bytes / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }
}
