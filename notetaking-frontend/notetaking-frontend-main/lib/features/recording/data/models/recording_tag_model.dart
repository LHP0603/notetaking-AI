import '../../domain/entities/recording_tag.dart';

class RecordingTagModel extends RecordingTag {
  const RecordingTagModel({
    required int id,
    required String recordingId,
    required String tag,
  }) : super(
         id: id,
         recordingId: recordingId,
         tag: tag,
       );

  factory RecordingTagModel.fromJson(Map<String, dynamic> json) {
    return RecordingTagModel(
      id: json['id'] as int,
      recordingId: json['recording_id'] as String,
      tag: json['tag'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'recording_id': recordingId,
      'tag': tag,
    };
  }

  factory RecordingTagModel.fromEntity(RecordingTag entity) {
    return RecordingTagModel(
      id: entity.id,
      recordingId: entity.recordingId,
      tag: entity.tag,
    );
  }
}

