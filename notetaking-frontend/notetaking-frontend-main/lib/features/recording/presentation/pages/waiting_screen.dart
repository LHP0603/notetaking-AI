import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../injection_container/injection_container.dart' as di;
import '../../../auth/data/datasources/auth_local_data_source.dart';
import '../bloc/recording_bloc.dart';
import '../bloc/recording_event.dart';
import '../bloc/recording_state.dart';

class WaitingScreen extends StatefulWidget {
  final File file;

  const WaitingScreen({super.key, required this.file});

  @override
  State<WaitingScreen> createState() => _WaitingScreenState();
}

class _WaitingScreenState extends State<WaitingScreen> {
  @override
  void initState() {
    super.initState();
    _startUpload();
  }

  Future<void> _startUpload() async {
    // Get user ID
    final authLocalDataSource = di.sl<AuthLocalDataSource>();
    final user = await authLocalDataSource.getCachedUser();
    final userId = user?.id ?? 'user_001';

    // Prepare title from filename
    final fileName = widget.file.path.split('/').last;
    final title = fileName.replaceAll(RegExp(r'\.[^.]+$'), '');

    if (mounted) {
      context.read<RecordingBloc>().add(
        UploadAndTranscribeRecordingRequested(
          audioFile: widget.file,
          title: title,
          userId: userId,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<RecordingBloc, RecordingState>(
      listener: (context, state) {
        if (state is UploadComplete) {
          if (context.mounted) {
            // Replace the waiting screen with transcription page to prevent going back to waiting
            context.go(
              '${AppRoutes.transcription}?title=${Uri.encodeComponent(state.recording.title)}&recordingId=${state.recordingId}',
            );
          }
        } else if (state is RecordingError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${state.message}'),
              backgroundColor: Colors.red,
            ),
          );
          context.pop(); // Go back to confirmation or recording page
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF101822),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
              ),
              const SizedBox(height: 24),
              const Text(
                'Uploading & Transcribing...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Please wait while we process your audio.',
                style: TextStyle(color: Colors.grey[400], fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
