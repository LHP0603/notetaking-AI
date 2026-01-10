import 'package:flutter/material.dart';
import '../../domain/entities/transcription_response.dart';
import '../../domain/entities/transcription_segment_response.dart';
import '../../domain/entities/transcription_word.dart';

class TranscriptionResultPage extends StatelessWidget {
  final TranscriptionResponse transcriptionResponse;

  const TranscriptionResultPage({
    Key? key,
    required this.transcriptionResponse,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transcription Result'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // TODO: Implement share functionality
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Summary',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildSummaryRow('Audio ID', transcriptionResponse.audioId.toString()),
                    _buildSummaryRow('Language', transcriptionResponse.languageCode),
                    _buildSummaryRow('Confidence', '${(transcriptionResponse.confidence * 100).toStringAsFixed(1)}%'),
                    _buildSummaryRow('Word Count', transcriptionResponse.wordCount.toString()),
                    _buildSummaryRow('Status', transcriptionResponse.status),
                    if (transcriptionResponse.durationTranscribed != null)
                      _buildSummaryRow('Duration', '${transcriptionResponse.durationTranscribed!.toStringAsFixed(1)}s'),
                    _buildSummaryRow('Processed At', _formatDateTime(transcriptionResponse.processedAt)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Full Transcript
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Full Transcript',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: SelectableText(
                        transcriptionResponse.transcript,
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Segments
            if (transcriptionResponse.segments.isNotEmpty) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Segments',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...transcriptionResponse.segments.asMap().entries.map(
                        (entry) => _buildSegmentCard(context, entry.key + 1, entry.value),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentCard(BuildContext context, int index, TranscriptionSegmentResponse segment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      elevation: 1,
      child: ExpansionTile(
        title: Text('Segment $index'),
        subtitle: Text(
          'Confidence: ${(segment.confidence * 100).toStringAsFixed(1)}% • ${segment.words.length} words',
          style: TextStyle(color: Colors.grey[600]),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SelectableText(
                  segment.transcript,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 12),
                if (segment.words.isNotEmpty) ...[
                  Text(
                    'Words',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children: segment.words.map((word) => _buildWordChip(word)).toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWordChip(TranscriptionWord word) {
    return Tooltip(
      message: 'Start: ${word.startTime.toStringAsFixed(2)}s\n'
          'End: ${word.endTime.toStringAsFixed(2)}s\n'
          'Confidence: ${(word.confidence * 100).toStringAsFixed(1)}%',
      child: Chip(
        label: Text(
          word.word,
          style: const TextStyle(fontSize: 12),
        ),
        backgroundColor: _getConfidenceColor(word.confidence),
      ),
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) {
      return Colors.green[100]!;
    } else if (confidence >= 0.6) {
      return Colors.orange[100]!;
    } else {
      return Colors.red[100]!;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}