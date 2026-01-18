import 'package:flutter/material.dart' hide Notification;
import '../../../../injection_container/injection_container.dart';
import '../../../audio_manager/domain/entities/audio_file.dart';
import '../../../audio_manager/domain/entities/note.dart';
import '../../../audio_manager/domain/repositories/audio_manager_repository.dart';
import '../../../audio_manager/presentation/pages/audio_detail_screen.dart';
import '../../domain/entities/notification.dart';

class NotificationDetailScreen extends StatelessWidget {
  final Notification notification;

  const NotificationDetailScreen({super.key, required this.notification});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101822),
      appBar: AppBar(
        backgroundColor: const Color(0xFF101822),
        elevation: 0,
        title: const Text('Notification Detail'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: notification.type.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    notification.type.icon,
                    color: notification.type.color,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatTimestamp(notification.createdAt),
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                notification.body,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (notification.relatedId != null) _buildActionButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context) {
    String buttonText;
    VoidCallback onPressed;

    switch (notification.type) {
      case NotificationType.transcriptionComplete:
      case NotificationType.audioProcessed:
        buttonText = 'View Audio';
        onPressed = () => _navigateToAudio(context, notification.relatedId!);
        break;
      case NotificationType.summarizationComplete:
      case NotificationType.noteCreated:
        buttonText = 'View Note';
        onPressed = () => _navigateToNote(context, notification.relatedId!);
        break;
      default:
        return const SizedBox.shrink();
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF3B82F6),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: Text(buttonText),
      ),
    );
  }

  Future<void> _navigateToAudio(BuildContext context, int audioId) async {
    final repository = sl<AudioManagerRepository>();
    final audioFile = await _runWithLoading<AudioFile?>(context, () async {
      final result = await repository.getAudioFileById(audioId);
      if (!context.mounted) {
        return null;
      }

      AudioFile? resolvedAudio;
      result.fold(
        (failure) => _showError(
          context,
          'Failed to load audio: ${failure.message}',
        ),
        (loadedAudio) => resolvedAudio = loadedAudio,
      );
      return resolvedAudio;
    });
    if (!context.mounted || audioFile == null) {
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AudioDetailScreen(audioFile: audioFile),
      ),
    );
  }

  Future<void> _navigateToNote(BuildContext context, int noteId) async {
    final repository = sl<AudioManagerRepository>();
    final audioFile = await _runWithLoading<AudioFile?>(context, () async {
      final noteResult = await repository.getNoteById(noteId);
      if (!context.mounted) {
        return null;
      }

      Note? note;
      noteResult.fold(
        (failure) => _showError(
          context,
          'Failed to load note: ${failure.message}',
        ),
        (loadedNote) => note = loadedNote,
      );

      if (note == null) {
        return null;
      }

      final audioResult = await repository.getAudioFileById(note!.audioFileId);
      if (!context.mounted) {
        return null;
      }

      AudioFile? resolvedAudio;
      audioResult.fold(
        (failure) => _showError(
          context,
          'Failed to load audio: ${failure.message}',
        ),
        (loadedAudio) => resolvedAudio = loadedAudio,
      );
      return resolvedAudio;
    });
    if (!context.mounted || audioFile == null) {
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AudioDetailScreen(audioFile: audioFile),
      ),
    );
  }

  Future<T?> _runWithLoading<T>(
    BuildContext context,
    Future<T?> Function() action,
  ) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      return await action();
    } finally {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    return '${timestamp.day}/${timestamp.month}/${timestamp.year} at ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
  }
}
