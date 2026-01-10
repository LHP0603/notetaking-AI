import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/summary_bloc.dart';
import '../bloc/summary_event.dart';

class ExportOptionsSheet extends StatefulWidget {
  final String recordingId;

  const ExportOptionsSheet({super.key, required this.recordingId});

  static void show(BuildContext context, String recordingId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C2128),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => ExportOptionsSheet(recordingId: recordingId),
    );
  }

  @override
  State<ExportOptionsSheet> createState() => _ExportOptionsSheetState();
}

class _ExportOptionsSheetState extends State<ExportOptionsSheet> {
  @override
  Widget build(BuildContext context) {
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
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Export Data',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildExportOption(
            context,
            title: 'Transcript PDF',
            icon: Icons.picture_as_pdf,
            type: 'TRANSCRIPT_PDF',
          ),
          _buildExportOption(
            context,
            title: 'Transcript Word',
            icon: Icons.description,
            type: 'TRANSCRIPT_DOCX',
          ),
          _buildExportOption(
            context,
            title: 'Summary PDF',
            icon: Icons.summarize,
            type: 'SUMMARY_PDF',
          ),
          _buildExportOption(
            context,
            title: 'Summary Word',
            icon: Icons.file_present,
            type: 'SUMMARY_DOCX',
          ),
          _buildExportOption(
            context,
            title: 'Full Archive (ZIP)',
            icon: Icons.archive,
            type: 'FULL_ZIP',
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildExportOption(
    BuildContext context, {
    required String title,
    required IconData icon,
    required String type,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      onTap: () {
        Navigator.pop(context);
        context.read<SummaryBloc>().add(
          ExportRecordingEvent(
            recordingId: widget.recordingId,
            exportType: type,
          ),
        );
      },
    );
  }
}
