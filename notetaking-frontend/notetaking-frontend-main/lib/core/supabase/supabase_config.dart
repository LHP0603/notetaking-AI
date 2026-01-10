class SupabaseConfig {
  // Storage bucket name for audio files
  static const String audioBucket = 'recordings';

  // Storage path patterns
  static String recordingPath(
    String userId,
    String recordingId,
    String fileName,
  ) {
    return '$userId/$recordingId/$fileName';
  }

  static String transcriptionPath(String userId, String fileName) {
    return 'transcriptions/$userId/$fileName';
  }

  // Generate unique file name with timestamp
  static String generateFileName(String originalFileName) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = originalFileName.split('.').last;
    final nameWithoutExtension = originalFileName
        .substring(0, originalFileName.lastIndexOf('.'))
        .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    return '${nameWithoutExtension}_$timestamp.$extension';
  }
}
