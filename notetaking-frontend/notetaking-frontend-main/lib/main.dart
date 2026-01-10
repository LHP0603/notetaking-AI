import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'injection_container/injection_container.dart' as di;
import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/supabase/supabase_client.dart';
import 'features/auth/data/datasources/auth_local_data_source.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/recording/presentation/bloc/recording_bloc.dart';
import 'features/transcription/presentation/bloc/transcription_bloc.dart';
import 'features/summary/presentation/bloc/summary_bloc.dart';
import 'features/profile/presentation/bloc/profile_bloc.dart';
import 'features/admin/presentation/bloc/admin_bloc.dart';
import 'features/summary/presentation/bloc/summary_event.dart';
import 'features/transcription/presentation/bloc/transcription_event.dart';
import 'features/recording/presentation/bloc/recording_event.dart';
import 'features/admin/presentation/bloc/admin_event.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load key from .env file
  await dotenv.load(fileName: '.env');
  final supabaseUrl = dotenv.env['SUPABASE_URL'];
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

  if (supabaseUrl == null || supabaseAnonKey == null) {
    throw Exception(
      'Missing Supabase credentials. Please ensure SUPABASE_URL and SUPABASE_ANON_KEY are set in your .env file.',
    );
  }

  try {
    // Initialize dependency injection first to get AuthLocalDataSource
    await di.init();

    // Get AuthLocalDataSource from dependency injection
    final authLocalDataSource = di.sl<AuthLocalDataSource>();

    // Initialize Supabase
    await SupabaseClient.initialize(
      supabaseUrl: supabaseUrl,
      supabaseAnonKey: supabaseAnonKey,
      authLocalDataSource: authLocalDataSource,
    );
  } catch (e) {
    // Handle initialization error
    debugPrint('Failed to initialize app: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(create: (_) => di.sl<AuthBloc>()),
        BlocProvider<RecordingBloc>(create: (_) => di.sl<RecordingBloc>()),
        BlocProvider<TranscriptionBloc>(
          create: (_) => di.sl<TranscriptionBloc>(),
        ),
        BlocProvider<SummaryBloc>(create: (_) => di.sl<SummaryBloc>()),
        BlocProvider<ProfileBloc>(create: (_) => di.sl<ProfileBloc>()),
        BlocProvider<AdminBloc>(create: (_) => di.sl<AdminBloc>()),
      ],
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthUnauthenticated) {
            // Global reset when user logs out
            context.read<SummaryBloc>().add(ResetSummaryEvent());
            context.read<TranscriptionBloc>().add(ResetTranscriptionEvent());
            context.read<RecordingBloc>().add(const ResetRecordingEvent());
            context.read<AdminBloc>().add(ResetAdminEvent());
            // ProfileBloc handles its own logout state
          }
        },
        child: MaterialApp.router(
          title: 'Voicely',
          theme: AppTheme.lightTheme,
          routerConfig: appRouter,
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
  }
}
