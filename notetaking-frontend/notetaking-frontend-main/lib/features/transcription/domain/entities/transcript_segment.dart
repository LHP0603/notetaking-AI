import 'package:equatable/equatable.dart';

class TranscriptSegment extends Equatable {
  final int segmentId; // bigint segment_id PK
  final String transcriptId; // uuid transcript_id FK
  final double startTime; // Thời gian bắt đầu (giây)
  final double endTime; // Thời gian kết thúc
  final String content; // Nội dung văn bản
  final String speakerLabel; // VD: SPEAKER_01
  final int? sequence; // Optional: segment sequence number
  final bool? isUserEdited; // Optional: whether segment was edited by user

  const TranscriptSegment({
    required this.segmentId,
    required this.transcriptId,
    required this.startTime,
    required this.endTime,
    required this.content,
    required this.speakerLabel,
    this.sequence,
    this.isUserEdited,
  });

  @override
  List<Object?> get props => [
    segmentId,
    transcriptId,
    startTime,
    endTime,
    content,
    speakerLabel,
    sequence,
    isUserEdited,
  ];
}

