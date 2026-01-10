class AppConstants {
  // API
  static const String baseUrl = 'http://10.0.2.2:8000';

  // Endpoints - Health & Auth
  static const String healthEndpoint = '/health';
  static const String loginEndpoint = '/auth/login';
  static const String signupEndpoint = '/auth/signup';
  static const String refreshTokenEndpoint = '/auth/refresh';
  static const String authMeEndpoint = '/auth/me';

  // Endpoints - Recordings
  static const String recordingsEndpoint = '/recordings/';
  static const String recordingsCompleteUploadEndpoint =
      '/recordings/:id/complete-upload';
  static const String recordingsRestoreEndpoint = '/recordings/:id/restore';
  static const String recordingsHardDeleteEndpoint =
      '/recordings/:id/hard-delete';

  // Endpoints - Folders
  static const String foldersEndpoint = '/folders/';
  
  // Endpoints - Transcription
  static const String recordingsTranscribeEndpoint =
      '/recordings/:id/transcribe';
  static const String recordingsTranscriptsEndpoint =
      '/recordings/:id/transcripts';
  static const String transcriptsEndpoint = '/transcripts/';
  static const String transcriptsSegmentsEndpoint =
      '/transcripts/:transcript_id/segments/:segment_id';

  // Endpoints - Summaries
  static const String recordingsSummarizeEndpoint = '/recordings/:id/summarize';
  static const String recordingsSummariesEndpoint = '/recordings/:id/summaries';
  static const String summariesEndpoint = '/summaries/';

  // Endpoints - Speakers
  static const String recordingsSpeakersEndpoint = '/recordings/:id/speakers';
  static const String recordingsSpeakersLabelEndpoint =
      '/recordings/:id/speakers/:speaker_label';

  // Endpoints - Tags & Markers
  static const String recordingsMarkersEndpoint = '/recordings/:id/markers';
  static const String markersEndpoint = '/markers';
  static const String recordingsTagsEndpoint = '/recordings/:id/tags';
  static const String recordingsTagsTagEndpoint = '/recordings/:id/tags/:tag';

  // Endpoints - Export Jobs
  static const String recordingsExportEndpoint = '/recordings/:id/export';
  static const String exportJobsEndpoint = '/export-jobs';

  // Endpoints - Admin
  static const String adminUsersEndpoint = '/admin/users';
  static const String adminUsersIdEndpoint = '/admin/users/:id';
  static const String adminUsersRecordingsEndpoint =
      '/admin/users/:id/recordings';
  static const String adminTiersEndpoint = '/admin/tiers';
  static const String adminTiersIdEndpoint = '/admin/tiers/:id';
  static const String adminAuditLogsEndpoint = '/admin/audit-logs';
  static const String adminRecordingsIdEndpoint = '/admin/recordings/:id';

  // Storage keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userDataKey = 'user_data';
  static const String isFirstTimeKey = 'is_first_time';

  // Timeouts
  static const int connectionTimeout = 30000; // 30 seconds
  static const int receiveTimeout = 30000; // 30 seconds

  // App Info
  static const String appName = 'Voicely';
  static const String appVersion = '1.0.0';
}
