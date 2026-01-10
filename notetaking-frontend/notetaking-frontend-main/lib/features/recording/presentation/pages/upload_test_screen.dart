import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/recording_bloc.dart';
import '../bloc/recording_event.dart';
import '../bloc/recording_state.dart';

class UploadTestScreen extends StatelessWidget {
  const UploadTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload & Transcribe Test'),
      ),
      body: BlocProvider(
        create: (context) => context.read<RecordingBloc>(),
        child: const UploadTestView(),
      ),
    );
  }
}

class UploadTestView extends StatefulWidget {
  const UploadTestView({super.key});

  @override
  State<UploadTestView> createState() => _UploadTestViewState();
}

class _UploadTestViewState extends State<UploadTestView> {
  File? _selectedFile;
  String? _fileName;

  void _pickFile() async {
    // For testing, you can use a file picker package like file_picker
    // For now, this is a placeholder - you'll need to implement file picking
    // or provide a test file path
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('File picker not implemented. Please provide a file path for testing.'),
      ),
    );
  }

  void _uploadAndTranscribe() {
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a file first'),
        ),
      );
      return;
    }

    // Get userId from auth - for testing, you might need to get this from your auth state
    // For now, using a placeholder
    const userId = 'test-user-id'; // TODO: Get from auth

    context.read<RecordingBloc>().add(
      UploadAndTranscribeRecordingRequested(
        audioFile: _selectedFile!,
        title: _fileName ?? 'Test Recording',
        userId: userId,
        folderId: null,
      ),
    );
  }

  String _formatDuration(double seconds) {
    final minutes = (seconds / 60).floor();
    final secs = (seconds % 60).floor();
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RecordingBloc, RecordingState>(
      listener: (context, state) {
        if (state is RecordingError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${state.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      builder: (context, state) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // File selection section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Select Audio File',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_selectedFile != null)
                        Text(
                          'Selected: ${_fileName ?? _selectedFile!.path}',
                          style: const TextStyle(fontSize: 14),
                        )
                      else
                        const Text(
                          'No file selected',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _pickFile,
                        icon: const Icon(Icons.attach_file),
                        label: const Text('Pick File'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Upload button
              ElevatedButton(
                onPressed: _selectedFile != null && 
                          state is! CreatingRecording &&
                          state is! UploadingToSupabase &&
                          state is! CompletingUpload &&
                          state is! TranscribingRecording &&
                          state is! FetchingSegments
                    ? _uploadAndTranscribe
                    : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Upload & Transcribe'),
              ),
              const SizedBox(height: 16),

              // Progress indicator
              if (state is CreatingRecording ||
                  state is UploadingToSupabase ||
                  state is CompletingUpload ||
                  state is TranscribingRecording ||
                  state is FetchingSegments)
                Card(
                  color: Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Progress',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (state is CreatingRecording)
                          const Row(
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(width: 16),
                              Text('Creating recording metadata...'),
                            ],
                          )
                        else if (state is UploadingToSupabase)
                          const Row(
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(width: 16),
                              Text('Uploading to Supabase Storage...'),
                            ],
                          )
                        else if (state is CompletingUpload)
                          const Row(
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(width: 16),
                              Text('Completing upload...'),
                            ],
                          )
                        else if (state is TranscribingRecording)
                          Row(
                            children: [
                              const CircularProgressIndicator(),
                              const SizedBox(width: 16),
                              Text('Transcribing recording ${state.recordingId}...'),
                            ],
                          )
                        else if (state is FetchingSegments)
                          Row(
                            children: [
                              const CircularProgressIndicator(),
                              const SizedBox(width: 16),
                              Text('Fetching segments for transcript ${state.transcriptId}...'),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),

              // Success state with segments
              if (state is UploadComplete)
                Card(
                  color: Colors.green.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.green),
                            const SizedBox(width: 8),
                            const Text(
                              'Upload Complete!',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text('Recording ID: ${state.recordingId}'),
                        Text('Transcript ID: ${state.transcriptId}'),
                        Text('Title: ${state.recording.title}'),
                        const SizedBox(height: 16),
                        Text(
                          'Segments (${state.segments.length})',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),

              // Segments list
              if (state is UploadComplete && state.segments.isNotEmpty)
                ...state.segments.map((segment) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(
                          segment.speakerLabel,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_formatDuration(segment.startTime)} - ${_formatDuration(segment.endTime)}',
                              style: const TextStyle(fontSize: 11),
                            ),
                            const SizedBox(height: 4),
                            Text(segment.content),
                          ],
                        ),
                        isThreeLine: true,
                      ),
                    )),
            ],
          ),
        );
      },
    );
  }
}

