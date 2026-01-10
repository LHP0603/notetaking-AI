import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../transcription/presentation/bloc/transcription_bloc.dart';
import '../../../transcription/presentation/bloc/transcription_event.dart';
import '../../../transcription/presentation/bloc/transcription_state.dart';
import '../../../transcription/presentation/pages/transcription_result_page.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../../core/routes/app_router.dart';

class TestPage extends StatefulWidget {
  const TestPage({Key? key}) : super(key: key);

  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  String? selectedFilePath;
  String selectedLanguage = 'vi-VN'; // Default to Vietnamese

  final List<Map<String, String>> supportedLanguages = [
    {'code': 'vi-VN', 'name': 'Vietnamese'},
    {'code': 'en-US', 'name': 'English (US)'},
    {'code': 'en-GB', 'name': 'English (UK)'},
    {'code': 'zh-CN', 'name': 'Chinese (Simplified)'},
    {'code': 'ja-JP', 'name': 'Japanese'},
    {'code': 'ko-KR', 'name': 'Korean'},
  ];

  void _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['wav', 'mp3', 'm4a', 'aac', 'flac', 'ogg'],
    );
    
    if (result != null && result.files.single.path != null) {
      setState(() {
        selectedFilePath = result.files.single.path;
      });
    }
  }

  void _uploadAndTranscribe() {
    // Check authentication state first
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Please login to upload and transcribe audio files',
          ),
          backgroundColor: Colors.orange,
          action: SnackBarAction(
            label: 'Login',
            onPressed: () => context.go(AppRoutes.login),
          ),
        ),
      );
      return;
    }

    if (selectedFilePath != null) {
      final file = File(selectedFilePath!);
      context.read<TranscriptionBloc>().add(UploadAudioFileEvent(file));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Audio Transcription')),
      body: BlocListener<TranscriptionBloc, TranscriptionState>(
        listener: (context, state) {
          if (state is TranscriptionError) {
            final isAuthError =
                state.message.toLowerCase().contains('login') ||
                state.message.toLowerCase().contains('unauthorized') ||
                state.message.toLowerCase().contains('token');

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: isAuthError ? Colors.orange : Colors.red,
                action:
                    isAuthError
                        ? SnackBarAction(
                          label: 'Login',
                          onPressed: () => context.go(AppRoutes.login),
                        )
                        : null,
              ),
            );
          } else if (state is AudioUploadSuccess) {
            // Auto-trigger transcription after successful upload
            context.read<TranscriptionBloc>().add(
              TranscribeAudioEvent(
                audioId: state.uploadResponse.audioFile.id,
                languageCode: selectedLanguage,
              ),
            );
          } else if (state is TranscriptionSuccess) {
            // Navigate to result page
            Navigator.of(context).push(
              MaterialPageRoute(
                builder:
                    (context) => TranscriptionResultPage(
                      transcriptionResponse: state.transcriptionResponse,
                    ),
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Language Selection
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select Language',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      DropdownButton<String>(
                        value: selectedLanguage,
                        isExpanded: true,
                        items:
                            supportedLanguages.map((language) {
                              return DropdownMenuItem<String>(
                                value: language['code'],
                                child: Text(language['name']!),
                              );
                            }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              selectedLanguage = newValue;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // File Selection
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Audio File',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Supported formats: WAV, MP3, M4A, AAC, FLAC, OGG\nMaximum file size: 50MB',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _pickFile,
                        icon: const Icon(Icons.folder_open),
                        label: const Text('Pick Audio File'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
                      if (selectedFilePath != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            border: Border.all(color: Colors.green[300]!),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: Colors.green[600],
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Selected: ${selectedFilePath!.split('/').last}',
                                  style: TextStyle(color: Colors.green[700]),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Upload and Transcribe Button
              BlocBuilder<AuthBloc, AuthState>(
                builder: (context, authState) {
                  final isAuthenticated = authState is AuthAuthenticated;

                  if (!isAuthenticated) {
                    return Card(
                      color: Colors.orange[50],
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Icon(
                              Icons.lock_outline,
                              size: 48,
                              color: Colors.orange[600],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Authentication Required',
                              style: Theme.of(
                                context,
                              ).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange[800],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Please login to upload and transcribe audio files',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.orange[700]),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () => context.go(AppRoutes.login),
                              icon: const Icon(Icons.login),
                              label: const Text('Login'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, 48),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return BlocBuilder<TranscriptionBloc, TranscriptionState>(
                    builder: (context, state) {
                      final isLoading = state is TranscriptionLoading;
                      return ElevatedButton.icon(
                        onPressed:
                            selectedFilePath != null && !isLoading
                                ? _uploadAndTranscribe
                                : null,
                        icon:
                            isLoading
                                ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                                : const Icon(Icons.upload_file),
                        label: Text(
                          isLoading
                              ? (state is AudioUploadSuccess
                                  ? 'Transcribing...'
                                  : 'Uploading...')
                              : 'Upload & Transcribe',
                        ),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 56),
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 16),

              // Instructions
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'How it works:',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text('1. Select your preferred language'),
                      const Text('2. Pick an audio file from your device'),
                      const Text('3. Tap "Upload & Transcribe" to start'),
                      const Text('4. View detailed results with timestamps'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
