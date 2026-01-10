import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../injection_container/injection_container.dart' as di;
import '../../../auth/data/datasources/auth_local_data_source.dart';
import '../bloc/recording_bloc.dart';
import '../bloc/recording_event.dart';
import '../bloc/recording_state.dart';

class RecordingPage extends StatelessWidget {
  const RecordingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<RecordingBloc, RecordingState>(
      listener: (context, state) async {
        if (state is RecordingError) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        } else if (state is RecordingCompleted) {
          // Get user ID from auth
          final authLocalDataSource = di.sl<AuthLocalDataSource>();
          final user = await authLocalDataSource.getCachedUser();
          final userId = user?.id ?? 'user_001'; // Fallback if no user

          // Get the audio file from the recording
          final audioFile = File(state.recording.filePath);

          // Check if file exists
          if (!await audioFile.exists()) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Error: Recording file not found'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }

          // Upload and transcribe the recorded audio
          context.read<RecordingBloc>().add(
            UploadAndTranscribeRecordingRequested(
              audioFile: audioFile,
              title: state.recording.title,
              userId: userId,
              folderId: state.recording.folderId,
            ),
          );
        } else if (state is AudioImported) {
          // Navigate to confirmation screen
          if (context.mounted) {
            context.pushNamed('confirmation', extra: {'file': state.audioFile});
          }
        } else if (state is RecordingTranscribed) {
          // Navigate to transcription page with transcriptId
          context.push(
            '${AppRoutes.transcription}?title=${Uri.encodeComponent(state.recording.title)}&transcriptId=${state.transcriptId}',
          );
        } else if (state is UploadComplete) {
          // Verify recordingId is valid before navigation
          if (state.recordingId.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Error: Recording ID is missing'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Upload and transcription completed: ${state.recording.title}',
              ),
              backgroundColor: const Color(0xFF10B981),
              duration: const Duration(seconds: 2),
            ),
          );

          // Navigate automatically to transcription page after successful upload
          // Using context.mounted check to ensure widget is still in tree
          if (context.mounted) {
            // Small delay to ensure snackbar is visible before navigation
            await Future.delayed(const Duration(milliseconds: 500));

            if (context.mounted) {
              context.push(
                '${AppRoutes.transcription}?title=${Uri.encodeComponent(state.recording.title)}&recordingId=${state.recordingId}',
              );
            }
          }
        } else if (state is UploadingRecording ||
            state is TranscribingRecording) {
          // Show loading indicator
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Uploading and transcribing...'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      },
      child: const _RecordingPageContent(),
    );
  }
}

class _RecordingPageContent extends StatefulWidget {
  const _RecordingPageContent();

  @override
  State<_RecordingPageContent> createState() => _RecordingPageContentState();
}

class _RecordingPageContentState extends State<_RecordingPageContent>
    with WidgetsBindingObserver {
  late RecorderController _recorderController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _recorderController = RecorderController();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _recorderController.dispose();
    super.dispose();
  }

  void _onImportPressed(BuildContext context) {
    context.read<RecordingBloc>().add(const ImportAudioRequested());
  }

  Future<void> _onRecordPressed(
    BuildContext context,
    RecordingState state,
  ) async {
    if (state is RecordingInProgress) {
      final path = await _recorderController.stop();
      if (path != null) {
        if (context.mounted) {
          context.read<RecordingBloc>().add(
            RecordingFinished(
              path: path,
              duration: _recorderController.elapsedDuration,
            ),
          );
        }
      }
    } else if (state is RecordingPaused) {
      await _recorderController.record();
      if (context.mounted)
        context.read<RecordingBloc>().add(const ResumeRecordingRequested());
    } else {
      // Start recording
      final hasPermission = await _recorderController.checkPermission();
      if (hasPermission) {
        await _recorderController.record();
        if (context.mounted) {
          context.read<RecordingBloc>().add(const StartRecordingRequested());

          // Update duration manually
          _recorderController.onCurrentDuration.listen((duration) {
            context.read<RecordingBloc>().add(DurationUpdated(duration));
          });
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Microphone permission required')),
          );
        }
      }
    }
  }

  void _onHistoryPressed(BuildContext context) {
    context.push(AppRoutes.transcriptList);
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return duration.inHours > 0
        ? '$hours:$minutes:$seconds'
        : '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;

    return Scaffold(
      backgroundColor: const Color(0xFF101822),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth > 600 ? screenWidth * 0.15 : 24.0,
          ),
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Row(
                  children: [
                    // History button
                    GestureDetector(
                      onTap: () => _onHistoryPressed(context),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.history,
                          color: Colors.grey[500],
                          size: 28,
                        ),
                      ),
                    ),
                    // Title
                    const Expanded(
                      child: Text(
                        'Voicely',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    // Placeholder for symmetry
                    const SizedBox(width: 40),
                  ],
                ),
              ),
              // Main content
              Expanded(
                child: BlocBuilder<RecordingBloc, RecordingState>(
                  builder: (context, state) {
                    final isRecording = state is RecordingInProgress;
                    final isPaused = state is RecordingPaused;

                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Title
                        Text(
                          isRecording
                              ? 'Recording...'
                              : isPaused
                              ? 'Paused'
                              : 'Ready to Capture?',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        // Subtitle or Duration
                        if (isRecording || isPaused)
                          Text(
                            _formatDuration(
                              isRecording
                                  ? state.duration
                                  : (state as RecordingPaused).duration,
                            ),
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.w300,
                              color:
                                  isRecording
                                      ? const Color(0xFF3B82F6)
                                      : Colors.grey[500],
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          )
                        else
                          Text(
                            'Tap to start recording or import an\nexisting audio file.',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[500],
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        // Waveform visualization
                        if (isRecording || isPaused) ...[
                          const SizedBox(height: 32),
                          Container(
                            height: 100,
                            margin: const EdgeInsets.symmetric(horizontal: 24),
                            child: AudioWaveforms(
                              enableGesture: false,
                              size: Size(
                                MediaQuery.of(context).size.width - 48,
                                100,
                              ),
                              recorderController: _recorderController,
                              waveStyle: const WaveStyle(
                                waveColor: Color(0xFF3B82F6),
                                extendWaveform: true,
                                showMiddleLine: false,
                                spacing: 8.0,
                              ),
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
              // Bottom action buttons
              Padding(
                padding: EdgeInsets.only(bottom: isSmallScreen ? 32 : 48),
                child: BlocBuilder<RecordingBloc, RecordingState>(
                  builder: (context, state) {
                    final isRecording = state is RecordingInProgress;
                    final isPaused = state is RecordingPaused;
                    final isActive = isRecording || isPaused;

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Import button (left)
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap:
                                  isActive
                                      ? null
                                      : () => _onImportPressed(context),
                              child: Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color:
                                      isActive
                                          ? const Color(
                                            0xFF282E39,
                                          ).withValues(alpha: 0.5)
                                          : const Color(0xFF282E39),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.file_upload_outlined,
                                  color:
                                      isActive
                                          ? Colors.grey[700]
                                          : Colors.white,
                                  size: 28,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Import',
                              style: TextStyle(
                                fontSize: 14,
                                color:
                                    isActive
                                        ? Colors.grey[700]
                                        : Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 40),
                        // Record button (center, larger, blue)
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: () => _onRecordPressed(context, state),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: isRecording ? 100 : 96,
                                height: isRecording ? 100 : 96,
                                decoration: BoxDecoration(
                                  color:
                                      isPaused
                                          ? const Color(0xFF282E39)
                                          : const Color(0xFF3B82F6),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF3B82F6).withValues(
                                        alpha: isRecording ? 0.4 : 0.2,
                                      ),
                                      blurRadius: isRecording ? 24 : 16,
                                      spreadRadius: isRecording ? 4 : 0,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  isRecording
                                      ? Icons.stop
                                      : isPaused
                                      ? Icons.play_arrow
                                      : Icons.mic,
                                  color: Colors.white,
                                  size: 40,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              isRecording
                                  ? 'Stop'
                                  : isPaused
                                  ? 'Resume'
                                  : 'Record',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                        // Spacer for symmetry (same width as Import button area)
                        const SizedBox(width: 40),
                        const SizedBox(width: 64),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
