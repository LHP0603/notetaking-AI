import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../bloc/summary_bloc.dart';
import '../bloc/summary_event.dart';
import '../bloc/summary_state.dart';
import '../../domain/entities/summary.dart';

import '../widgets/summary_section_card.dart';
import '../widgets/summary_content_sections.dart';
import '../widgets/folder_picker_sheet.dart';
import '../widgets/export_options_sheet.dart';

class SummaryScreen extends StatefulWidget {
  final String recordingId;
  final String? meetingTitle;

  const SummaryScreen({
    super.key,
    required this.recordingId,
    this.meetingTitle,
  });

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  @override
  void initState() {
    super.initState();
    context.read<SummaryBloc>().add(
      LoadSummaryForRecordingEvent(widget.recordingId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return BlocListener<SummaryBloc, SummaryState>(
      listener: (context, state) {
        if (state is SummaryError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        } else if (state is ExportSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message ?? 'Export ready! Downloading...'),
              backgroundColor: Colors.green,
            ),
          );
          if (state.downloadUrl.isNotEmpty) {
            _launchURL(state.downloadUrl);
          }
        } else if (state is RecordingSaved) {
          final folderName = state.folderName ?? 'folder';
          final message =
              folderName == 'Root level'
                  ? 'Summary saved to root level'
                  : 'Summary saved to folder $folderName';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
          // Navigate back to summary_list_screen after successful save
          Future.delayed(const Duration(milliseconds: 800), () {
            if (context.mounted) {
              context.goNamed('transcriptList');
            }
          });
        }
      },
      child: BlocBuilder<SummaryBloc, SummaryState>(
        buildWhen: (previous, current) {
          return current is SummaryLoading ||
              current is SummaryLoaded ||
              current is SummaryError ||
              current is RecordingSaved ||
              current is SummarySaving ||
              current is ExportingSummary ||
              current is ExportSuccess;
        },
        builder: (context, state) {
          if (state is RecordingSaved) {
            state = SummaryLoaded(state.summary);
          }

          if (state is SummarySaving) {
            state = SummaryLoaded(state.summary);
          }

          if (state is ExportingSummary) {
            state = SummaryLoaded(state.summary);
          }

          if (state is SummaryLoading) {
            return Scaffold(
              backgroundColor: const Color(0xFF101822),
              body: const Center(
                child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
              ),
            );
          }

          if (state is SummaryError) {
            return Scaffold(
              backgroundColor: const Color(0xFF101822),
              body: SafeArea(
                child: Column(
                  children: [
                    // Header
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal:
                            screenWidth > 600 ? screenWidth * 0.1 : 16.0,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => context.pop(),
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
                          const Expanded(
                            child: Text(
                              'Summary',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(width: 40), // Balance the back button
                        ],
                      ),
                    ),
                    // Error content
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 64,
                            ),
                            const SizedBox(height: 16),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                              ),
                              child: Text(
                                state.message,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: () {
                                context.read<SummaryBloc>().add(
                                  LoadSummaryForRecordingEvent(
                                    widget.recordingId,
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF3B82F6),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
                              child: const Text(
                                'Retry',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is SummaryLoaded) {
            return _buildSummaryContent(context, state.summary, screenWidth);
          }

          return Scaffold(
            backgroundColor: const Color(0xFF101822),
            body: const Center(
              child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryContent(
    BuildContext context,
    Summary summary,
    double screenWidth,
  ) {
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
                  GestureDetector(
                    onTap: () => context.pop(),
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
                  Expanded(
                    child: Column(
                      children: [
                        const Text(
                          'Summary',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (widget.meetingTitle != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            widget.meetingTitle!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[400],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 40), // Balance the back button
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth > 600 ? screenWidth * 0.1 : 16.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Overview Section
                    SummarySectionCard(
                      icon: const Icon(
                        Icons.auto_awesome,
                        color: Color(0xFF60A5FA),
                        size: 20,
                      ),
                      title: 'Overview',
                      iconColor: const Color(0xFF60A5FA),
                      content: OverviewSection(
                        overview: summary.contentStructure.overview,
                      ),
                    ),
                    // Key Points Section
                    if (summary.contentStructure.keyPoints.isNotEmpty)
                      SummarySectionCard(
                        icon: const Icon(
                          Icons.lightbulb_outline,
                          color: Color(0xFF10B981),
                          size: 20,
                        ),
                        title: 'Key Points',
                        iconColor: const Color(0xFF10B981),
                        content: KeyPointsSection(
                          keyPoints: summary.contentStructure.keyPoints,
                        ),
                      ),
                    // Action Items Section
                    if (summary.contentStructure.actionItems.isNotEmpty)
                      SummarySectionCard(
                        icon: const Icon(
                          Icons.check_circle_outline,
                          color: Color(0xFF9333EA),
                          size: 20,
                        ),
                        title: 'Action Items',
                        iconColor: const Color(0xFF9333EA),
                        content: ActionItemsSection(
                          actionItems: summary.contentStructure.actionItems,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Bottom buttons
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  // Re-summary button
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _onResummarizePressed(context),
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: const Color(0xFF282E39),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.refresh, color: Colors.white, size: 18),
                            SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'Re-summary',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Save button
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _onSavePressed(context),
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Save',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 6),
                            Icon(Icons.save, color: Colors.white, size: 18),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Export button
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _showExportOptions(context),
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: const Color(0xFF282E39),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.download, color: Colors.white, size: 18),
                            SizedBox(width: 6),
                            Text(
                              'Export',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
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

  void _onResummarizePressed(BuildContext context) {
    context.read<SummaryBloc>().add(
      ResummarizeRecordingEvent(widget.recordingId),
    );
  }

  void _onSavePressed(BuildContext context) {
    _showFolderPickerDialog(context);
  }

  Future<void> _showFolderPickerDialog(BuildContext context) async {
    await FolderPickerSheet.show(context, widget.recordingId);
  }

  void _showExportOptions(BuildContext context) {
    ExportOptionsSheet.show(context, widget.recordingId);
  }

  Future<void> _launchURL(String url) async {
    debugPrint('Attempting to launch export URL: $url');
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      debugPrint('canLaunchUrl returned true. Launching...');
      final result = await launchUrl(uri, mode: LaunchMode.externalApplication);
      debugPrint('launchUrl result: $result');
    } else {
      debugPrint('canLaunchUrl returned false.');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch export URL')),
        );
      }
    }
  }
}
