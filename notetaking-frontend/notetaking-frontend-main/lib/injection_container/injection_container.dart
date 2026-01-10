import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Core
import '../core/network/network_client.dart';
import '../core/network/network_info.dart';
import '../core/supabase/supabase_client.dart';

// Features - Auth
import '../features/auth/data/datasources/auth_local_data_source.dart';
import '../features/auth/data/datasources/auth_remote_data_source.dart';
import '../features/auth/data/repositories/auth_repository_impl.dart';
import '../features/auth/domain/repositories/auth_repository.dart';
import '../features/auth/domain/usecases/login_user.dart';
import '../features/auth/domain/usecases/signup_user.dart';
import '../features/auth/domain/usecases/logout_user.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';

// Features - Recording
import '../features/recording/data/datasources/recording_local_data_source.dart';
import '../features/recording/data/datasources/recording_remote_data_source.dart';
import '../features/recording/data/repositories/recording_repository_impl.dart';
import '../features/recording/domain/repositories/recording_repository.dart';
import '../features/recording/domain/usecases/start_recording.dart';
import '../features/recording/domain/usecases/stop_recording.dart';
import '../features/recording/domain/usecases/import_audio.dart';
import '../features/recording/presentation/bloc/recording_bloc.dart';
import '../features/recording/presentation/bloc/recordings_list_bloc.dart';

// Features - Transcription
import '../features/transcription/data/datasources/transcription_remote_data_source.dart';
import '../features/transcription/data/repositories/transcription_repository_impl.dart';
import '../features/transcription/domain/repositories/transcription_repository.dart';
import '../features/transcription/domain/usecases/upload_audio.dart';
import '../features/transcription/domain/usecases/transcribe_audio.dart';
import '../features/transcription/domain/usecases/get_transcript_detail.dart';
import '../features/transcription/presentation/bloc/transcription_bloc.dart';

// Features - Folder
import '../features/folder/data/datasources/folder_remote_data_source.dart';
import '../features/folder/data/repositories/folder_repository_impl.dart';
import '../features/folder/domain/repositories/folder_repository.dart';
import '../features/folder/domain/usecases/create_folder.dart';
import '../features/folder/domain/usecases/get_folders.dart';
import '../features/folder/domain/usecases/update_folder.dart';
import '../features/folder/domain/usecases/delete_folder.dart';

// Features - Summary
import '../features/summary/data/datasources/summary_remote_data_source.dart';
import '../features/summary/data/datasources/summary_local_data_source.dart';
import '../features/summary/data/repositories/summary_repository_impl.dart';
import '../features/summary/domain/repositories/summary_repository.dart';
import '../features/summary/domain/usecases/get_summary.dart';
import '../features/summary/domain/usecases/save_summary.dart';
import '../features/summary/domain/usecases/resummarize.dart';
import '../features/summary/domain/usecases/update_action_item.dart';
import '../features/summary/domain/usecases/get_latest_summary_for_recording.dart';
import '../features/summary/presentation/bloc/summary_bloc.dart';

// Features - Profile
import '../features/profile/data/datasources/profile_remote_data_source.dart';
import '../features/profile/data/datasources/profile_local_data_source.dart';
import '../features/profile/data/repositories/profile_repository_impl.dart';
import '../features/profile/domain/repositories/profile_repository.dart';
import '../features/profile/domain/usecases/get_profile.dart';
import '../features/profile/domain/usecases/update_profile.dart';
import '../features/profile/domain/usecases/logout.dart';
import '../features/profile/presentation/bloc/profile_bloc.dart';

// Features - Admin
import '../features/admin/data/datasources/admin_remote_data_source.dart';
import '../features/admin/data/repositories/admin_repository_impl.dart';
import '../features/admin/domain/repositories/admin_repository.dart';
import '../features/admin/presentation/bloc/admin_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  //! Features - Auth
  // Bloc
  sl.registerFactory(
    () => AuthBloc(loginUser: sl(), signupUser: sl(), logoutUser: sl()),
  );

  // Use cases
  sl.registerLazySingleton(() => LoginUser(sl()));
  sl.registerLazySingleton(() => SignupUser(sl()));
  sl.registerLazySingleton(() => LogoutUser(sl()));

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

  //! Features - Recording
  // Bloc
  sl.registerFactory(
    () => RecordingBloc(
      startRecording: sl(),
      stopRecording: sl(),
      importAudio: sl(),
      repository: sl(),
    ),
  );

  // Recordings List Bloc
  sl.registerFactory(
    () => RecordingsListBloc(recordingRepository: sl(), folderRepository: sl()),
  );

  // Use cases
  sl.registerLazySingleton(() => StartRecording(sl()));
  sl.registerLazySingleton(() => StopRecording(sl()));
  sl.registerLazySingleton(() => ImportAudio(sl()));

  // Repository
  sl.registerLazySingleton<RecordingRepository>(
    () => RecordingRepositoryImpl(
      localDataSource: sl(),
      remoteDataSource: sl(),
      networkInfo: sl(),
      authLocalDataSource: sl(),
      transcriptionRepository: sl(),
    ),
  );

  // Data sources
  sl.registerLazySingleton<RecordingLocalDataSource>(
    () => RecordingLocalDataSourceImpl(),
  );
  sl.registerLazySingleton<RecordingRemoteDataSource>(
    () => RecordingRemoteDataSourceImpl(dio: sl(), supabaseClient: sl()),
  );

  //! Features - Transcription
  // Bloc
  sl.registerFactory(
    () => TranscriptionBloc(
      uploadAudio: sl(),
      transcribeAudio: sl(),
      getTranscriptDetail: sl(),
      transcriptionRepository: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => UploadAudio(sl()));
  sl.registerLazySingleton(() => TranscribeAudio(sl()));
  sl.registerLazySingleton(() => GetTranscriptDetail(sl()));

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
    () => TranscriptionRemoteDataSourceImpl(dio: sl(), supabaseClient: sl()),
  );

  //! Features - Folder
  // Use cases
  sl.registerLazySingleton(() => CreateFolder(sl()));
  sl.registerLazySingleton(() => GetFolders(sl()));
  sl.registerLazySingleton(() => UpdateFolder(sl()));
  sl.registerLazySingleton(() => DeleteFolder(sl()));

  // Repository
  sl.registerLazySingleton<FolderRepository>(
    () => FolderRepositoryImpl(
      remoteDataSource: sl(),
      networkInfo: sl(),
      authLocalDataSource: sl(),
    ),
  );

  // Data sources
  sl.registerLazySingleton<FolderRemoteDataSource>(
    () => FolderRemoteDataSourceImpl(dio: sl()),
  );

  //! Features - Summary
  // Bloc
  sl.registerFactory(
    () => SummaryBloc(
      getSummary: sl(),
      saveSummary: sl(),
      resummarize: sl(),
      updateActionItem: sl(),
      getLatestSummaryForRecording: sl(),
      recordingRepository: sl(),
      folderRepository: sl(),
      summaryRepository: sl(),
      summaryRemoteDataSource: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => GetSummary(sl()));
  sl.registerLazySingleton(() => SaveSummary(sl()));
  sl.registerLazySingleton(() => Resummarize(sl()));
  sl.registerLazySingleton(() => UpdateActionItem(sl()));
  sl.registerLazySingleton(() => GetLatestSummaryForRecording(sl()));

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

  //! Features - Profile
  // Bloc
  sl.registerFactory(
    () => ProfileBloc(
      getProfile: sl(),
      updateProfile: sl(),
      logout: sl(),
      repository: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => GetProfile(sl()));
  sl.registerLazySingleton(() => UpdateProfile(sl()));
  sl.registerLazySingleton(() => Logout(sl()));

  // Repository
  sl.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      authLocalDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  // Data sources
  sl.registerLazySingleton<ProfileRemoteDataSource>(
    () => ProfileRemoteDataSourceImpl(dio: sl()),
  );
  sl.registerLazySingleton<ProfileLocalDataSource>(
    () => ProfileLocalDataSourceImpl(sharedPreferences: sl()),
  );

  //! Core
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl());

  //! Supabase
  // Note: SupabaseClient must be initialized before this point
  // The instance will be registered after initialization in main.dart
  sl.registerLazySingleton<SupabaseClient>(() => SupabaseClient.instance);

  //! External
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);

  // Register AuthLocalDataSource first
  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(sharedPreferences: sl()),
  );

  final networkClient = NetworkClient(
    authLocalDataSource: sl<AuthLocalDataSource>(),
  );
  sl.registerLazySingleton(() => networkClient.dio);

  //! Features - Admin
  // Bloc
  sl.registerFactory(() => AdminBloc(adminRepository: sl()));

  // Repository
  sl.registerLazySingleton<AdminRepository>(
    () => AdminRepositoryImpl(remoteDataSource: sl(), networkInfo: sl()),
  );

  // Data sources
  sl.registerLazySingleton<AdminRemoteDataSource>(
    () => AdminRemoteDataSourceImpl(dio: sl()),
  );
}
