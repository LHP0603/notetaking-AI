import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routes/app_router.dart';
import '../bloc/transcription_bloc.dart';
import '../bloc/transcription_event.dart';
import '../bloc/transcription_state.dart';
import '../../domain/entities/transcript_segment.dart';
import '../../domain/entities/recording_speaker.dart';

class TranscriptEntry {
  final String speakerId;
  final String speakerName;
  final String speakerInitials;
  final Color speakerColor;
  final Duration timestamp;
  final String text;

  TranscriptEntry({
    required this.speakerId,
    required this.speakerName,
    required this.speakerInitials,
    required this.speakerColor,
    required this.timestamp,
    required this.text,
  });
}

class TranscriptionPage extends StatefulWidget {
  final String? meetingTitle;
  final Duration? audioDuration;
  final String? transcriptId;
  final String? recordingId;

  const TranscriptionPage({
    super.key,
    this.meetingTitle,
    this.audioDuration,
    this.transcriptId,
    this.recordingId,
  });

  @override
  State<TranscriptionPage> createState() => _TranscriptionPageState();
}

class _TranscriptionPageState extends State<TranscriptionPage> {
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  List<TranscriptEntry> _transcriptEntries = [];
  Map<String, RecordingSpeaker> _speakersMap = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    final bloc = context.read<TranscriptionBloc>();

    // Prioritize recordingId if provided (new flow)
    if (widget.recordingId != null) {
      bloc.add(LoadTranscriptByRecordingIdEvent(widget.recordingId!));
    } else if (widget.transcriptId != null) {
      // Fallback to transcriptId for backward compatibility
      bloc.add(LoadTranscriptDetailEvent(widget.transcriptId!));
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  // Map transcript segments to UI entries
  void _mapTranscriptToEntries(
    List<TranscriptSegment> segments,
    List<RecordingSpeaker> speakers,
  ) {
    // Create speakers map for quick lookup
    _speakersMap = {
      for (var speaker in speakers) speaker.speakerLabel: speaker,
    };

    // Map segments to entries
    _transcriptEntries =
        segments.map((segment) {
          final speaker = _speakersMap[segment.speakerLabel];
          final speakerLabel = segment.speakerLabel;

          // Get speaker info or use defaults
          String speakerName;
          String speakerInitials;
          Color speakerColor;

          if (speaker != null) {
            speakerName = speaker.displayName;
            speakerInitials = _getInitials(speaker.displayName);
            speakerColor = _parseColor(speaker.color) ?? Colors.grey;
          } else {
            // Default for unknown speakers
            speakerName = speakerLabel;
            speakerInitials = speakerLabel.replaceAll('SPEAKER_', 'S');
            speakerColor = Colors.grey;
          }

          return TranscriptEntry(
            speakerId: speakerLabel,
            speakerName: speakerName,
            speakerInitials: speakerInitials,
            speakerColor: speakerColor,
            timestamp: Duration(
              milliseconds: (segment.startTime * 1000).round(),
            ),
            text: segment.content,
          );
        }).toList();

    // Calculate total duration from last segment
    if (segments.isNotEmpty) {
      final lastSegment = segments.last;
      _totalDuration = Duration(
        milliseconds: (lastSegment.endTime * 1000).round(),
      );
    }
  }

  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty) {
      return parts[0]
          .substring(0, parts[0].length > 2 ? 2 : parts[0].length)
          .toUpperCase();
    }
    return 'U';
  }

  Color? _parseColor(String? colorString) {
    if (colorString == null || colorString.isEmpty) return null;
    try {
      // Remove # if present and parse hex
      final hex = colorString.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return null;
    }
  }

  // Mock data removed

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  void _onBackPressed() {
    context.pop();
  }

  void _onSharePressed() {
    // TODO: Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share functionality coming soon')),
    );
  }

  void _onPlayPausePressed() {
    setState(() {
      _isPlaying = !_isPlaying;
    });
    // TODO: Implement audio playback
  }

  void _onDiscardPressed() {
    // TODO: Implement discard functionality
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF282E39),
            title: const Text(
              'Discard Transcript?',
              style: TextStyle(color: Colors.white),
            ),
            content: const Text(
              'Are you sure you want to discard this transcript? This action cannot be undone.',
              style: TextStyle(color: Colors.grey),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.pop();
                },
                child: const Text(
                  'Discard',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  void _onGenerateSummaryPressed() {
    // Navigate to summary page with recordingId if available
    if (widget.recordingId != null) {
      context.push(
        '${AppRoutes.summary}?title=${Uri.encodeComponent(widget.meetingTitle ?? 'Meeting with Design Team')}&recordingId=${widget.recordingId}',
      );
    } else {
      // Fallback to legacy summary page if no recordingId
      context.push(
        '${AppRoutes.summary}?title=${Uri.encodeComponent(widget.meetingTitle ?? 'Meeting with Design Team')}',
      );
    }
  }

  Widget _buildSpeakerAvatar(TranscriptEntry entry) {
    if (entry.speakerColor == Colors.grey) {
      // Generic speaker icon
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.grey[700],
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.person, color: Colors.grey[400], size: 24),
      );
    } else {
      // Colored circle with initials
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: entry.speakerColor,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            entry.speakerInitials,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }
  }

  // Widget _buildWaveform() {
  //   return const SizedBox(height: 40);
  // }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return BlocListener<TranscriptionBloc, TranscriptionState>(
      listener: (context, state) {
        if (state is TranscriptionError) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
          setState(() {
            _isLoading = false;
          });
        } else if (state is TranscriptDetailLoaded) {
          setState(() {
            _mapTranscriptToEntries(
              state.transcriptDetail.segments,
              state.speakers,
            );
            _isLoading = false;
          });
        }
      },
      child: BlocBuilder<TranscriptionBloc, TranscriptionState>(
        builder: (context, state) {
          if (state is TranscriptionLoading || _isLoading) {
            return Scaffold(
              backgroundColor: const Color(0xFF101822),
              body: const Center(child: CircularProgressIndicator()),
            );
          }

          // Use real data if available
          final entries = _transcriptEntries;

          return Scaffold(
            backgroundColor: const Color(0xFF101822),
            body: SafeArea(
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth > 600 ? screenWidth * 0.1 : 16.0,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        // Back button
                        GestureDetector(
                          onTap: _onBackPressed,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.arrow_back,
                              color: Colors.grey[500],
                              size: 24,
                            ),
                          ),
                        ),
                        // Title
                        Expanded(
                          child: Text(
                            'Review Transcript',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        // Share button
                        GestureDetector(
                          onTap: _onSharePressed,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.share,
                              color: Colors.grey[500],
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Meeting title
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      widget.meetingTitle ?? 'Meeting with Design Team',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[400],
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // // Audio player
                  // Padding(
                  //   padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  //   child: Row(
                  //     children: [
                  //       // Play button
                  //       GestureDetector(
                  //         onTap: _onPlayPausePressed,
                  //         child: Container(
                  //           width: 48,
                  //           height: 48,
                  //           decoration: BoxDecoration(
                  //             color: const Color(0xFF3B82F6),
                  //             shape: BoxShape.circle,
                  //           ),
                  //           child: Icon(
                  //             _isPlaying ? Icons.pause : Icons.play_arrow,
                  //             color: Colors.white,
                  //             size: 28,
                  //           ),
                  //         ),
                  //       ),
                  //       const SizedBox(width: 12),
                  //       // Waveform
                  //       Expanded(child: _buildWaveform()),
                  //       const SizedBox(width: 12),
                  //       // Timestamps
                  //       Column(
                  //         crossAxisAlignment: CrossAxisAlignment.end,
                  //         children: [
                  //           Text(
                  //             _formatDuration(_currentPosition),
                  //             style: const TextStyle(
                  //               fontSize: 14,
                  //               fontWeight: FontWeight.w600,
                  //               color: Colors.white,
                  //             ),
                  //           ),
                  //           Text(
                  //             _formatDuration(_totalDuration),
                  //             style: TextStyle(
                  //               fontSize: 12,
                  //               color: Colors.grey[500],
                  //             ),
                  //           ),
                  //         ],
                  //       ),
                  //     ],
                  //   ),
                  // ),
                  // const SizedBox(height: 24),
                  // Transcript content
                  Expanded(
                    child: ListView.builder(
                      padding: EdgeInsets.symmetric(
                        horizontal:
                            screenWidth > 600 ? screenWidth * 0.1 : 16.0,
                      ),
                      itemCount: entries.length,
                      itemBuilder: (context, index) {
                        final entry = entries[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Speaker avatar
                              _buildSpeakerAvatar(entry),
                              const SizedBox(width: 12),
                              // Transcript content
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Speaker name and timestamp
                                    Row(
                                      children: [
                                        Text(
                                          entry.speakerName,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _formatDuration(entry.timestamp),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[500],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    // Transcript text
                                    Text(
                                      entry.text,
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: Colors.grey[300],
                                        height: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  // Bottom buttons
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        // Discard button
                        Expanded(
                          child: GestureDetector(
                            onTap: _onDiscardPressed,
                            child: Container(
                              height: 50,
                              decoration: BoxDecoration(
                                color: const Color(0xFF282E39),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Center(
                                child: Text(
                                  'Discard',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Generate Summary button
                        Expanded(
                          flex: 2,
                          child: GestureDetector(
                            onTap: _onGenerateSummaryPressed,
                            child: Container(
                              height: 50,
                              decoration: BoxDecoration(
                                color: const Color(0xFF3B82F6),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.auto_awesome,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Generate Summary',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(width: 6),
                                  Icon(
                                    Icons.auto_awesome,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
