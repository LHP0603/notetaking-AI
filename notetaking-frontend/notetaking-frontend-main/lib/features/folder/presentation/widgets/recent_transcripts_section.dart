import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routes/app_router.dart';
import '../../../summary/presentation/bloc/summary_bloc.dart';
import '../../../summary/presentation/bloc/summary_event.dart';
import '../../../summary/domain/entities/summary.dart';
import '../../../recording/domain/entities/recording.dart';
import 'transcript_card.dart';
import 'edit_transcript_dialog.dart';

class RecentTranscriptsSection extends StatelessWidget {
  final List<Summary> summaries;
  final Map<String, Recording> recordingsMap;

  const RecentTranscriptsSection({
    super.key,
    required this.summaries,
    required this.recordingsMap,
  });

  @override
  Widget build(BuildContext context) {
    // Sort summaries by date (most recent first)
    final sortedSummaries = List<Summary>.from(summaries)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // Take only the most recent 3 for the "Recent" section
    final recentSummaries = sortedSummaries.take(3).toList();

    if (recentSummaries.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Transcripts',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: recentSummaries.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final summary = recentSummaries[index];
            final recording = recordingsMap[summary.recordingId];
            final title = recording?.title ?? 'Untitled Recording';
            final date = summary.createdAt;
            final isPinned = recording?.isPinned ?? false;

            return TranscriptCard(
              title: title,
              date: date,
              isPinned: isPinned,
              onTap: () async {
                if (recording != null) {
                  await context.push(
                    '${AppRoutes.summary}?recordingId=${recording.recordingId}&title=${Uri.encodeComponent(title)}',
                  );
                  // Reload list when returning
                  if (context.mounted) {
                    context.read<SummaryBloc>().add(
                      const LoadSummariesListEvent(),
                    );
                  }
                }
              },
              onMoreTap:
                  recording != null
                      ? () => _showTranscriptOptions(context, recording)
                      : null,
            );
          },
        ),
      ],
    );
  }

  void _showTranscriptOptions(BuildContext context, Recording recording) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C2128),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final isPinned = recording.isPinned;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.blue),
                title: const Text(
                  'Rename',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder:
                        (context) => EditTranscriptDialog(recording: recording),
                  );
                },
              ),
              ListTile(
                leading: Icon(
                  isPinned ? Icons.push_pin_outlined : Icons.push_pin,
                  color: Colors.orange,
                ),
                title: Text(
                  isPinned ? 'Unpin' : 'Pin',
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  context.read<SummaryBloc>().add(
                    UpdateRecordingEvent(
                      recordingId: recording.recordingId,
                      isPinned: !isPinned,
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text(
                  'Move to Trash',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  // Soft Delete
                  context.read<SummaryBloc>().add(
                    DeleteRecordingEvent(recording.recordingId),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
