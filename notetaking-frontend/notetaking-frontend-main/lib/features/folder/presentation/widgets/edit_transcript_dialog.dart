import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../summary/presentation/bloc/summary_bloc.dart';
import '../../../summary/presentation/bloc/summary_event.dart';
import '../../../recording/domain/entities/recording.dart';

class EditTranscriptDialog extends StatefulWidget {
  final Recording recording;

  const EditTranscriptDialog({super.key, required this.recording});

  @override
  State<EditTranscriptDialog> createState() => _EditTranscriptDialogState();
}

class _EditTranscriptDialogState extends State<EditTranscriptDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.recording.title);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1F2937),
      title: const Text(
        'Rename Transcript',
        style: TextStyle(color: Colors.white),
      ),
      content: TextField(
        controller: _controller,
        style: const TextStyle(color: Colors.black),
        cursorColor: Colors.white,
        decoration: const InputDecoration(
          hintText: 'Enter new name',
          hintStyle: TextStyle(color: Colors.grey),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.grey),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF3B82F6)),
          ),
        ),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            final newName = _controller.text.trim();
            if (newName.isNotEmpty && newName != widget.recording.title) {
              context.read<SummaryBloc>().add(
                UpdateRecordingEvent(
                  recordingId: widget.recording.recordingId,
                  title: newName,
                ),
              );
            }
            Navigator.pop(context);
          },
          child: const Text('Save', style: TextStyle(color: Color(0xFF3B82F6))),
        ),
      ],
    );
  }
}
