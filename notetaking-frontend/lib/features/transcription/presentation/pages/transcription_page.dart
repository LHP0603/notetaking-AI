import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routes/app_router.dart';

// Mock data model for transcript entries
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

  const TranscriptionPage({super.key, this.meetingTitle, this.audioDuration});

  @override
  State<TranscriptionPage> createState() => _TranscriptionPageState();
}

class _TranscriptionPageState extends State<TranscriptionPage> {
  bool _isPlaying = false;
  Duration _currentPosition = const Duration(seconds: 14);
  final Duration _totalDuration = const Duration(minutes: 14, seconds: 32);

  // Mock transcript data
  final List<TranscriptEntry> _transcriptEntries = [
    TranscriptEntry(
      speakerId: 'jd',
      speakerName: 'John Doe',
      speakerInitials: 'JD',
      speakerColor: const Color(0xFF9333EA), // Purple
      timestamp: const Duration(seconds: 0),
      text:
          'Alright everyone, let\'s get started. The main goal for today is to finalize the UI for the new dashboard.',
    ),
    TranscriptEntry(
      speakerId: 'sa',
      speakerName: 'Sarah A.',
      speakerInitials: 'SA',
      speakerColor: const Color(0xFF10B981), // Green
      timestamp: const Duration(seconds: 14),
      text:
          'I\'ve updated the mockups based on last week\'s feedback. I think the dark mode toggle is much smoother now.',
    ),
    TranscriptEntry(
      speakerId: 's3',
      speakerName: 'Speaker 3',
      speakerInitials: 'S3',
      speakerColor: Colors.grey,
      timestamp: const Duration(seconds: 32),
      text:
          'Can we also look at the mobile responsiveness? I noticed some padding issues on the iPhone 15 layout.',
    ),
    TranscriptEntry(
      speakerId: 'jd',
      speakerName: 'John Doe',
      speakerInitials: 'JD',
      speakerColor: const Color(0xFF9333EA),
      timestamp: const Duration(seconds: 45),
      text:
          'Good catch. Let\'s add that to the Jira ticket. Sarah, can you share your screen?',
    ),
    TranscriptEntry(
      speakerId: 'sa',
      speakerName: 'Sarah A.',
      speakerInitials: 'SA',
      speakerColor: const Color(0xFF10B981),
      timestamp: const Duration(seconds: 52),
      text: 'Sure, give me a second. Is everyone seeing the Figma file?',
    ),
    TranscriptEntry(
      speakerId: 's4',
      speakerName: 'Speaker 4',
      speakerInitials: 'S4',
      speakerColor: Colors.grey,
      timestamp: const Duration(seconds: 65),
      text: 'Yes, we can see it clearly now.',
    ),
  ];

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
    // Navigate to summary page
    context.push(
      '${AppRoutes.summary}?title=${Uri.encodeComponent(widget.meetingTitle ?? 'Meeting with Design Team')}',
    );
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

  Widget _buildWaveform() {
    return Container(
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(50, (index) {
          final isActive = index < 20; // Mock active waveform
          return Container(
            width: 3,
            height: isActive ? 20 + (index % 5) * 4.0 : 8.0,
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFF3B82F6) : Colors.grey[700],
              borderRadius: BorderRadius.circular(1.5),
            ),
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

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
            // Audio player
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  // Play button
                  GestureDetector(
                    onTap: _onPlayPausePressed,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Waveform
                  Expanded(child: _buildWaveform()),
                  const SizedBox(width: 12),
                  // Timestamps
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatDuration(_currentPosition),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        _formatDuration(_totalDuration),
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Transcript content
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth > 600 ? screenWidth * 0.1 : 16.0,
                ),
                itemCount: _transcriptEntries.length,
                itemBuilder: (context, index) {
                  final entry = _transcriptEntries[index];
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
  }
}
