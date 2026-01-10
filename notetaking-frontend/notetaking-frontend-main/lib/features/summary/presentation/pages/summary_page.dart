import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/summary_bloc.dart';
import '../bloc/summary_event.dart';
import '../bloc/summary_state.dart';
import '../../domain/entities/summary.dart';
import '../../domain/entities/action_item.dart';

class SummaryPage extends StatelessWidget {
  final String? meetingTitle;
  final String? transcriptionId;

  const SummaryPage({super.key, this.meetingTitle, this.transcriptionId});

  @override
  Widget build(BuildContext context) {
    // If transcriptionId is provided, fetch the summary
    if (transcriptionId != null) {
      context.read<SummaryBloc>().add(GetSummaryEvent(transcriptionId!));
    }

    return BlocListener<SummaryBloc, SummaryState>(
      listener: (context, state) {
        if (state is SummaryError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        } else if (state is SummarySaved) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Summary saved successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      },
      child: BlocBuilder<SummaryBloc, SummaryState>(
        builder: (context, state) {
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
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      state.message,
                      style: const TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.pop(),
                      child: const Text('Go Back'),
                    ),
                  ],
                ),
              ),
            );
          }

          // Use loaded summary or show empty state
          Summary? summary;
          if (state is SummaryLoaded) {
            summary = state.summary;
          } else if (state is SummarySaved) {
            summary = state.summary;
          }

          if (summary == null) {
            // Show empty state or mock data for preview
            return _buildEmptyState(context);
          }

          return _buildSummaryContent(context, summary);
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    // This can be used for preview or when no summary is loaded
    return Scaffold(
      backgroundColor: const Color(0xFF101822),
      body: const Center(
        child: Text(
          'No summary available',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildSummaryContent(BuildContext context, Summary summary) {
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
                  // Title and subtitle
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
                        const SizedBox(height: 4),
                        Text(
                          meetingTitle ?? 'Meeting Summary',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[400],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  // Share button
                  GestureDetector(
                    onTap: () => _onSharePressed(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.share,
                        color: Color(0xFF3B82F6),
                        size: 24,
                      ),
                    ),
                  ),
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
                    // Executive Summary
                    _buildSectionCard(
                      icon: const Icon(
                        Icons.auto_awesome,
                        color: Color(0xFF60A5FA),
                        size: 20,
                      ),
                      title: 'EXECUTIVE SUMMARY',
                      iconColor: const Color(0xFF60A5FA),
                      content: _buildExecutiveSummary(summary.executiveSummary),
                    ),
                    // Key Takeaways
                    _buildSectionCard(
                      icon: const Icon(
                        Icons.lightbulb_outline,
                        color: Color(0xFF10B981),
                        size: 20,
                      ),
                      title: 'Key Takeaways',
                      iconColor: const Color(0xFF10B981),
                      content: _buildKeyTakeaways(summary.keyTakeaways),
                    ),
                    // Action Items
                    _buildSectionCard(
                      icon: const Icon(
                        Icons.check_circle_outline,
                        color: Color(0xFF9333EA),
                        size: 20,
                      ),
                      title: 'Action Items',
                      iconColor: const Color(0xFF9333EA),
                      content: _buildActionItems(
                        context,
                        summary.actionItems,
                        summary.summaryId,
                      ),
                    ),
                    // Tags removed - not in database schema
                  ],
                ),
              ),
            ),
            // Bottom buttons
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  // Re-summarize button
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
                            Icon(Icons.refresh, color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Re-summarize',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Save Summary button
                  Expanded(
                    flex: 2,
                    child: GestureDetector(
                      onTap: () => _onSaveSummaryPressed(context, summary),
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
                              'Save Summary',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.save, color: Colors.white, size: 20),
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

  void _onSharePressed(BuildContext context) {
    // TODO: Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share functionality coming soon')),
    );
  }

  void _onResummarizePressed(BuildContext context) {
    if (transcriptionId != null) {
      context.read<SummaryBloc>().add(ResummarizeEvent(transcriptionId!));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot resummarize: No transcription ID'),
        ),
      );
    }
  }

  void _onSaveSummaryPressed(BuildContext context, Summary summary) {
    context.read<SummaryBloc>().add(SaveSummaryEvent(summary));
  }

  void _onActionItemToggled(
    BuildContext context,
    String summaryId,
    String actionItemId,
    bool currentStatus,
  ) {
    context.read<SummaryBloc>().add(
      UpdateActionItemEvent(
        summaryId: summaryId,
        actionItemId: actionItemId,
        isCompleted: !currentStatus,
      ),
    );
  }

  Widget _buildSectionCard({
    required Widget icon,
    required String title,
    required Widget content,
    Color? iconColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF282E39),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              icon,
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: iconColor ?? Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          content,
        ],
      ),
    );
  }

  Widget _buildExecutiveSummary(String executiveSummary) {
    // Highlight "dark mode toggle" in blue (or any other keywords)
    final textParts = executiveSummary.split('dark mode toggle');
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 15, color: Colors.white, height: 1.6),
        children: [
          TextSpan(text: textParts[0]),
          if (textParts.length > 1) ...[
            const TextSpan(
              text: 'dark mode toggle',
              style: TextStyle(color: Color(0xFF3B82F6)),
            ),
            TextSpan(text: textParts[1]),
          ] else
            TextSpan(text: executiveSummary),
        ],
      ),
    );
  }

  Widget _buildKeyTakeaways(List<String> keyTakeaways) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:
          keyTakeaways.map((takeaway) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 6, right: 12),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.grey[500],
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      takeaway,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.white,
                        height: 1.6,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }

  Widget _buildActionItems(
    BuildContext context,
    List<ActionItem> actionItems,
    String? summaryId,
  ) {
    if (summaryId == null) {
      // If no summaryId, show read-only action items
      return _buildActionItemsReadOnly(actionItems);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:
          actionItems.map((item) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1F2329),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap:
                            () => _onActionItemToggled(
                              context,
                              summaryId,
                              item.id,
                              item.isCompleted,
                            ),
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white, width: 2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child:
                              item.isCompleted
                                  ? const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 16,
                                  )
                                  : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item.text,
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.white,
                            decoration:
                                item.isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Color(item.assignedToColorValue),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            item.assignedToInitials,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        item.assignedToName,
                        style: TextStyle(fontSize: 13, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }

  Widget _buildActionItemsReadOnly(List<ActionItem> actionItems) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:
          actionItems.map((item) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1F2329),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white, width: 2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child:
                            item.isCompleted
                                ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 16,
                                )
                                : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item.text,
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.white,
                            decoration:
                                item.isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Color(item.assignedToColorValue),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            item.assignedToInitials,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        item.assignedToName,
                        style: TextStyle(fontSize: 13, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }

}
