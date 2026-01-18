import 'package:get_it/get_it.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Core
import '../core/network/network_client.dart';
import '../core/network/network_info.dart';

// Features - Auth
import '../features/auth/data/datasources/auth_local_data_source.dart';
import '../features/auth/data/datasources/auth_remote_data_source.dart';
import '../features/auth/data/repositories/auth_repository_impl.dart';
import '../features/auth/domain/repositories/auth_repository.dart';
import '../features/auth/domain/usecases/get_stored_auth.dart';
import '../features/auth/domain/usecases/login_user.dart';
import '../features/auth/domain/usecases/refresh_token.dart';
import '../features/auth/domain/usecases/logout_user.dart';
import '../features/auth/domain/usecases/register_user.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';

// Features - Audio Manager
import '../features/audio_manager/data/datasources/audio_manager_local_data_source.dart';
import '../features/audio_manager/data/datasources/audio_manager_remote_data_source.dart';
import '../features/audio_manager/data/repositories/audio_manager_repository_impl.dart';
import '../features/audio_manager/domain/repositories/audio_manager_repository.dart';
import '../features/audio_manager/domain/usecases/filter_audios.dart';
import '../features/audio_manager/domain/usecases/get_pending_tasks.dart';
import '../features/audio_manager/domain/usecases/get_server_tasks.dart';
import '../features/audio_manager/domain/usecases/get_uploaded_audios.dart';
import '../features/audio_manager/domain/usecases/search_audios.dart';
import '../features/audio_manager/domain/usecases/search_tasks.dart';
import '../features/audio_manager/domain/usecases/upload_audio_file.dart';
import '../features/audio_manager/presentation/bloc/audio_manager_bloc.dart';
import '../features/audio_manager/presentation/bloc/task_monitor_bloc.dart';

// Features - Recording
import '../features/recording/data/datasources/recording_local_data_source.dart';
import '../features/recording/data/datasources/recording_remote_data_source.dart';
import '../features/recording/data/repositories/recording_repository_impl.dart';
import '../features/recording/domain/repositories/recording_repository.dart';
import '../features/recording/domain/usecases/start_recording.dart';
import '../features/recording/domain/usecases/stop_recording.dart';
import '../features/recording/domain/usecases/import_audio.dart';
import '../features/recording/domain/usecases/upload_recording_async.dart';
import '../features/recording/presentation/bloc/recording_bloc.dart';

// Features - Transcription
import '../features/transcription/data/datasources/transcription_remote_data_source.dart';
import '../features/transcription/data/repositories/transcription_repository_impl.dart';
import '../features/transcription/domain/repositories/transcription_repository.dart';
import '../features/transcription/domain/usecases/upload_audio.dart';
import '../features/transcription/domain/usecases/transcribe_audio.dart';
import '../features/transcription/presentation/bloc/transcription_bloc.dart';

// Features - Summary
import '../features/summary/data/datasources/summary_remote_data_source.dart';
import '../features/summary/data/datasources/summary_local_data_source.dart';
import '../features/summary/data/repositories/summary_repository_impl.dart';
import '../features/summary/domain/repositories/summary_repository.dart';
import '../features/summary/domain/usecases/get_summary.dart';
import '../features/summary/domain/usecases/save_summary.dart';
import '../features/summary/domain/usecases/resummarize.dart';
import '../features/summary/domain/usecases/update_action_item.dart';
import '../features/summary/presentation/bloc/summary_bloc.dart';
// Features - Chatbot
import '../features/chatbot/data/datasources/chatbot_local_data_source.dart';
import '../features/chatbot/data/datasources/chatbot_remote_data_source.dart';
import '../features/chatbot/data/repositories/chatbot_repository_impl.dart';
import '../features/chatbot/domain/repositories/chatbot_repository.dart';
// Features - Notifications
import '../features/notifications/data/datasources/notification_remote_data_source.dart';
import '../features/notifications/data/repositories/notification_repository_impl.dart';
import '../features/notifications/domain/repositories/notification_repository.dart';
import '../features/notifications/domain/usecases/get_notification_by_id.dart';
import '../features/notifications/domain/usecases/get_notifications.dart';
import '../features/notifications/domain/usecases/get_unread_count.dart';
import '../features/notifications/domain/usecases/mark_all_notifications_as_read.dart';
import '../features/notifications/domain/usecases/mark_notifications_as_read.dart';
import '../features/notifications/presentation/bloc/notification_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  //! Features - Auth
  // Bloc
  sl.registerFactory(
    () => AuthBloc(
      registerUser: sl(),
      loginUser: sl(),
      refreshToken: sl(),
      logoutUser: sl(),
      getStoredAuth: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => RegisterUser(sl()));
  sl.registerLazySingleton(() => LoginUser(sl()));
  sl.registerLazySingleton(() => RefreshTokenUseCase(sl()));
  sl.registerLazySingleton(() => LogoutUser(sl()));
  sl.registerLazySingleton(() => GetStoredAuth(sl()));

  // Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  // Data sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(dio: sl()),
  );

  //! Features - Audio Manager
  // Bloc
  sl.registerFactory(
    () => AudioManagerBloc(
      getUploadedAudios: sl(),
      uploadAudioFile: sl(),
      getServerTasks: sl(),
      getPendingTasks: sl(),
      searchAudios: sl(),
      filterAudios: sl(),
    ),
  );
  sl.registerFactory(() => TaskMonitorBloc(searchTasks: sl()));

  // Use cases
  sl.registerLazySingleton(() => GetUploadedAudios(sl()));
  sl.registerLazySingleton(() => UploadAudioFile(sl()));
  sl.registerLazySingleton(() => GetServerTasks(sl()));
  sl.registerLazySingleton(() => GetPendingTasks(sl()));
  sl.registerLazySingleton(() => SearchAudios(sl()));
  sl.registerLazySingleton(() => SearchTasks(sl()));
  sl.registerLazySingleton(() => FilterAudios(sl()));

  // Repository
  sl.registerLazySingleton<AudioManagerRepository>(
    () => AudioManagerRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
      authLocalDataSource: sl(),
    ),
  );

  // Data sources
  sl.registerLazySingleton<AudioManagerRemoteDataSource>(
    () => AudioManagerRemoteDataSourceImpl(dio: sl()),
  );

  //! Features - Recording
  // Bloc
  sl.registerFactory(
    () => RecordingBloc(
      startRecording: sl(),
      stopRecording: sl(),
      importAudio: sl(),
      uploadRecordingAsync: sl(),
      repository: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => StartRecording(sl()));
  sl.registerLazySingleton(() => StopRecording(sl()));
  sl.registerLazySingleton(() => ImportAudio(sl()));
  sl.registerLazySingleton(() => UploadRecordingAsync(sl()));

  // Repository
  sl.registerLazySingleton<RecordingRepository>(
    () => RecordingRepositoryImpl(
      localDataSource: sl(),
      remoteDataSource: sl(),
      networkInfo: sl(),
      authLocalDataSource: sl(),
    ),
  );

  // Data sources
  sl.registerLazySingleton<RecordingLocalDataSource>(
    () => RecordingLocalDataSourceImpl(),
  );
  sl.registerLazySingleton<RecordingRemoteDataSource>(
    () => RecordingRemoteDataSourceImpl(dio: sl()),
  );

  //! Features - Transcription
  // Bloc
  sl.registerFactory(
    () => TranscriptionBloc(uploadAudio: sl(), transcribeAudio: sl()),
  );

  // Use cases
  sl.registerLazySingleton(() => UploadAudio(sl()));
  sl.registerLazySingleton(() => TranscribeAudio(sl()));

  // Repository
  sl.registerLazySingleton<TranscriptionRepository>(
    () => TranscriptionRepositoryImpl(
      remoteDataSource: sl(),
      networkInfo: sl(),
      authLocalDataSource: sl(),
    ),
  );

  // Data sources
  sl.registerLazySingleton<TranscriptionRemoteDataSource>(
    () => TranscriptionRemoteDataSourceImpl(dio: sl()),
  );

  //! Features - Summary
  // Bloc
  sl.registerFactory(
    () => SummaryBloc(
      getSummary: sl(),
      saveSummary: sl(),
      resummarize: sl(),
      updateActionItem: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => GetSummary(sl()));
  sl.registerLazySingleton(() => SaveSummary(sl()));
  sl.registerLazySingleton(() => Resummarize(sl()));
  sl.registerLazySingleton(() => UpdateActionItem(sl()));

  // Repository
  sl.registerLazySingleton<SummaryRepository>(
    () => SummaryRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
      authLocalDataSource: sl(),
    ),
  );

  // Data sources
  sl.registerLazySingleton<SummaryRemoteDataSource>(
    () => SummaryRemoteDataSourceImpl(dio: sl()),
  );
  sl.registerLazySingleton<SummaryLocalDataSource>(
    () => SummaryLocalDataSourceImpl(sharedPreferences: sl()),
  );

  //! Features - Chatbot
  sl.registerLazySingleton<ChatbotRepository>(
    () => ChatbotRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
      authLocalDataSource: sl(),
    ),
  );

  sl.registerLazySingleton<ChatbotRemoteDataSource>(
    () => ChatbotRemoteDataSourceImpl(dio: sl()),
  );

  sl.registerLazySingleton<ChatbotLocalDataSource>(
    () => ChatbotLocalDataSourceImpl(sharedPreferences: sl()),
  );

  //! Features - Notifications
  // Bloc
  sl.registerFactory(
    () => NotificationBloc(
      getNotifications: sl(),
      getUnreadCount: sl(),
      getNotificationById: sl(),
      markNotificationsAsRead: sl(),
      markAllNotificationsAsRead: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => GetNotifications(sl()));
  sl.registerLazySingleton(() => GetUnreadCount(sl()));
  sl.registerLazySingleton(() => GetNotificationById(sl()));
  sl.registerLazySingleton(() => MarkNotificationsAsRead(sl()));
  sl.registerLazySingleton(() => MarkAllNotificationsAsRead(sl()));

  // Repository
  sl.registerLazySingleton<NotificationRepository>(
    () => NotificationRepositoryImpl(
      remoteDataSource: sl(),
      networkInfo: sl(),
      authLocalDataSource: sl(),
    ),
  );

  // Data sources
  sl.registerLazySingleton<NotificationRemoteDataSource>(
    () => NotificationRemoteDataSourceImpl(dio: sl()),
  );

  //! Core
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl());

  //! External
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);

  sl.registerLazySingleton(() => const FlutterSecureStorage());

  // Register AuthLocalDataSource first
  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(
      sharedPreferences: sl(),
      secureStorage: sl(),
    ),
  );

  sl.registerLazySingleton<AudioManagerLocalDataSource>(
    () => AudioManagerLocalDataSourceImpl(sharedPreferences: sl()),
  );

  final networkClient = NetworkClient(
    authLocalDataSource: sl<AuthLocalDataSource>(),
  );
  sl.registerLazySingleton(() => networkClient.dio);
}
