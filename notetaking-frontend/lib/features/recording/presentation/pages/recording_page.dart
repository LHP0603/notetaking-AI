import 'dart:io';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../injection_container/injection_container.dart';
import '../../../audio_manager/presentation/bloc/audio_manager_bloc.dart';
import '../../../audio_manager/presentation/bloc/audio_manager_event.dart';
import '../../../audio_manager/presentation/bloc/task_monitor_bloc.dart';
import '../../../audio_manager/presentation/pages/audio_manager_page.dart';
import '../../../chatbot/presentation/pages/chatbot_screen.dart';
import '../../../chatbot/presentation/widgets/animated_chat_fab.dart';
import '../../../notifications/presentation/bloc/notification_bloc.dart';
import '../../../notifications/presentation/pages/notification_screen.dart';
import '../../../profile/presentation/pages/profile_screen.dart';
import '../../../transcription/presentation/pages/transcript_list_screen.dart';
import '../../domain/entities/recording.dart';
import '../bloc/recording_bloc.dart';
import '../bloc/recording_event.dart';
import '../bloc/recording_state.dart';

class RecordingPage extends StatefulWidget {
  const RecordingPage({super.key});

  @override
  State<RecordingPage> createState() => _RecordingPageState();
}

class _RecordingPageState extends State<RecordingPage> {
  final GlobalKey<CurvedNavigationBarState> _bottomNavigationKey = GlobalKey();
  int _page = 2;
  bool _hasShownLimitNotice = false;
  File? _pendingUploadFile;
  String? _audioManagerTab;

  List<Widget> get _pages => [
        const TranscriptListScreen(),
        AudioManagerPage(initialTab: _audioManagerTab),
        const _RecordingView(),
        const NotificationScreen(),
        const ProfileScreen(),
      ];

  void _onRecordPressed(BuildContext context, RecordingState state) {
    if (state is RecordingInProgress) {
      context.read<RecordingBloc>().add(const StopRecordingRequested());
    } else if (state is RecordingPaused) {
      context.read<RecordingBloc>().add(const ResumeRecordingRequested());
    } else {
      context.read<RecordingBloc>().add(const StartRecordingRequested());
    }
  }

  void _onBottomNavTapped(int index, RecordingState state) {
    if (index == 2 && _page == 2) {
      _onRecordPressed(context, state);
    }

    setState(() {
      _page = index;
      // Reset audio manager tab when navigating away or manually tapping
      if (index != 1) {
        _audioManagerTab = null;
      }
    });
  }

  void _openChatbot() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (context) => const ChatbotScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AudioManagerBloc>(
          create:
              (context) => sl<AudioManagerBloc>()
                ..add(const LoadUploadedAudios())
                ..add(const LoadPendingAudios()),
        ),
        BlocProvider<TaskMonitorBloc>(
          create: (context) => sl<TaskMonitorBloc>(),
        ),
        BlocProvider<NotificationBloc>(
          create: (context) => sl<NotificationBloc>(),
        ),
      ],
      child: BlocListener<RecordingBloc, RecordingState>(
        listener: (context, state) {
          if (state is RecordingInProgress &&
              state.duration == Duration.zero &&
              !_hasShownLimitNotice) {
            _hasShownLimitNotice = true;
            _pendingUploadFile = null;
            _showRecordingLimitNotification(context);
          } else if (state is RecordingCompletedMaxDuration) {
            _hasShownLimitNotice = false;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 5),
              ),
            );
            _uploadRecording(context, state.recording);
          } else if (state is RecordingCompleted) {
            _hasShownLimitNotice = false;
            _uploadRecording(context, state.recording);
          } else if (state is RecordingUploadSuccess) {
            _pendingUploadFile = null;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
            
            // Switch to Audio Manager -> Tasks tab without pushing new route
            setState(() {
              _audioManagerTab = 'tasks';
              _page = 1;
              
              // Also update the bottom nav bar UI state
              final navState = _bottomNavigationKey.currentState;
              if (navState != null) {
                navState.setPage(1);
              }
            });
          } else if (state is RecordingError) {
            final action =
                _pendingUploadFile == null
                    ? null
                    : SnackBarAction(
                      label: 'Retry',
                      onPressed: () {
                        final file = _pendingUploadFile;
                        if (file != null) {
                          context.read<RecordingBloc>().add(
                            UploadRecordingRequested(file),
                          );
                        }
                      },
                    );
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                action: action,
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is AudioImported) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Audio imported: ${state.audioFile.path.split('/').last}',
                ),
              ),
            );
            // Note: In real app, we might want to let AudioManager handle this
            // But preserving existing behavior for now if needed,
            // or we could dispatch to AudioManagerBloc here.
          }
        },
        child: BlocBuilder<RecordingBloc, RecordingState>(
          builder: (context, state) {
            final isRecording = state is RecordingInProgress;
            final isPaused = state is RecordingPaused;
            final unreadCount =
                context.watch<NotificationBloc>().state.unreadCount;

            return Scaffold(
              backgroundColor: const Color(0xFF101822),
              body: IndexedStack(index: _page, children: _pages),
              floatingActionButton: AnimatedChatFab(onPressed: _openChatbot),
              bottomNavigationBar: CurvedNavigationBar(
                key: _bottomNavigationKey,
                index: _page,
                height: 75.0,
                items: <Widget>[
                  const Icon(
                    Icons.folder_outlined,
                    size: 30,
                    color: Colors.white,
                  ),
                  const Icon(
                    Icons.file_upload_outlined,
                    size: 30,
                    color: Colors.white,
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: isRecording ? 48 : 44,
                        height: isRecording ? 48 : 44,
                        decoration: BoxDecoration(
                          color:
                              isPaused
                                  ? const Color(0xFF282E39)
                                  : const Color(0xFF3B82F6),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF3B82F6,
                              ).withValues(alpha: isRecording ? 0.4 : 0.2),
                              blurRadius: isRecording ? 12 : 8,
                              spreadRadius: isRecording ? 2 : 0,
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
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(
                        Icons.notifications,
                        size: 30,
                        color: Colors.white,
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              unreadCount > 99 ? '99+' : '$unreadCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const Icon(
                    Icons.person_outline,
                    size: 30,
                    color: Colors.white,
                  ),
                ],
                color: const Color(0xFF282E39),
                buttonBackgroundColor: const Color(0xFF282E39),
                backgroundColor: const Color(0xFF101822),
                animationCurve: Curves.easeInOut,
                animationDuration: const Duration(milliseconds: 600),
                onTap: (index) => _onBottomNavTapped(index, state),
                letIndexChange: (index) => true,
              ),
            );
          },
        ),
      ),
    );
  }

  void _showRecordingLimitNotification(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Recording limit: 2 hours maximum',
          style: TextStyle(fontSize: 16),
        ),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 4),
      ),
    );
  }

  void _uploadRecording(BuildContext context, Recording recording) {
    final path = recording.filePath;
    if (path == null || path.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Recording file path is missing'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final file = File(path);
    _pendingUploadFile = file;
    context.read<RecordingBloc>().add(UploadRecordingRequested(file));
  }
}

class _RecordingView extends StatelessWidget {
  const _RecordingView();

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
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth > 600 ? screenWidth * 0.15 : 24.0,
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    'Voicely',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: BlocBuilder<RecordingBloc, RecordingState>(
                builder: (context, state) {
                  final isRecording = state is RecordingInProgress;
                  final isPaused = state is RecordingPaused;
                  Duration? duration;
                  if (state is RecordingInProgress) {
                    duration = state.duration;
                  } else if (state is RecordingPaused) {
                    duration = state.duration;
                  }

                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
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
                      if (duration != null)
                        Text(
                          _formatDuration(duration),
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w300,
                            color:
                                isRecording
                                    ? const Color(0xFF3B82F6)
                                    : Colors.grey[500],
                            fontFeatures: const [FontFeature.tabularFigures()],
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
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
