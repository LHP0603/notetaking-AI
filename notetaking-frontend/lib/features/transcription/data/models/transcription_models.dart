class TranscriptionRequest {
  final int audioId;
  final String languageCode;

  TranscriptionRequest({
    required this.audioId,
    required this.languageCode,
  });

  Map<String, dynamic> toJson() {
    return {
      'audio_id': audioId,
      'language_code': languageCode,
    };
  }
}

class TranscriptionResponse {
  final int audioId;
  final String transcript;
  final double confidence;
  final String languageCode;
  final List<TranscriptionSegment> segments;
  final int wordCount;
  final double? durationTranscribed;
  final String status;
  final DateTime processedAt;

  TranscriptionResponse({
    required this.audioId,
    required this.transcript,
    required this.confidence,
    required this.languageCode,
    required this.segments,
    required this.wordCount,
    this.durationTranscribed,
    required this.status,
    required this.processedAt,
  });

  factory TranscriptionResponse.fromJson(Map<String, dynamic> json) {
    return TranscriptionResponse(
      audioId: json['audio_id'],
      transcript: json['transcript'],
      confidence: json['confidence'].toDouble(),
      languageCode: json['language_code'],
      segments: (json['segments'] as List)
          .map((segment) => TranscriptionSegment.fromJson(segment))
          .toList(),
      wordCount: json['word_count'],
      durationTranscribed: json['duration_transcribed']?.toDouble(),
      status: json['status'],
      processedAt: DateTime.parse(json['processed_at']),
    );
  }
}

class TranscriptionSegment {
  final String transcript;
  final double confidence;
  final List<TranscriptionWord> words;

  TranscriptionSegment({
    required this.transcript,
    required this.confidence,
    required this.words,
  });

  factory TranscriptionSegment.fromJson(Map<String, dynamic> json) {
    return TranscriptionSegment(
      transcript: json['transcript'],
      confidence: json['confidence'].toDouble(),
      words: (json['words'] as List)
          .map((word) => TranscriptionWord.fromJson(word))
          .toList(),
    );
  }
}

class TranscriptionWord {
  final String word;
  final double startTime;
  final double endTime;
  final double confidence;

  TranscriptionWord({
    required this.word,
    required this.startTime,
    required this.endTime,
    required this.confidence,
  });

  factory TranscriptionWord.fromJson(Map<String, dynamic> json) {
    return TranscriptionWord(
      word: json['word'],
      startTime: json['start_time'].toDouble(),
      endTime: json['end_time'].toDouble(),
      confidence: json['confidence'].toDouble(),
    );
  }
}