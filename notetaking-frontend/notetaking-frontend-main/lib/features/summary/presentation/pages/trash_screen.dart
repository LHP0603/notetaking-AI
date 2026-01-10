import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../bloc/summary_bloc.dart';
import '../bloc/summary_event.dart';
import '../bloc/summary_state.dart';

import '../../../recording/domain/entities/recording.dart';

class TrashScreen extends StatefulWidget {
  const TrashScreen({super.key});

  @override
  State<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen> {
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    context.read<SummaryBloc>().add(const LoadTrashedRecordingsEvent());
  }

  void _onRestore(Recording recording) {
    context.read<SummaryBloc>().add(
      RestoreRecordingEvent(recording.recordingId),
    );
    setState(() {
      _hasChanges = true;
    });
  }

  void _onHardDelete(Recording recording) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF1F2937),
            title: const Text(
              'Delete Forever?',
              style: TextStyle(color: Colors.white),
            ),
            content: const Text(
              'This action cannot be undone. The recording will be permanently deleted.',
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.read<SummaryBloc>().add(
                    HardDeleteRecordingEvent(recording.recordingId),
                  );
                  setState(() {
                    _hasChanges = true;
                  });
                },
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  void _showOptions(Recording recording) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C2128),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (context) => SafeArea(
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
                  leading: const Icon(Icons.restore, color: Colors.blue),
                  title: const Text(
                    'Restore',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _onRestore(recording);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_forever, color: Colors.red),
                  title: const Text(
                    'Delete Permanently',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _onHardDelete(recording);
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_hasChanges) {
          context.pop(true);
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF101822),
        appBar: AppBar(
          backgroundColor: const Color(0xFF101822),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              if (_hasChanges) {
                context.pop(true);
              } else {
                context.pop();
              }
            },
          ),
          title: const Text(
            'Trash',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        body: BlocConsumer<SummaryBloc, SummaryState>(
          listener: (context, state) {
            if (state is SummaryError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            } else if (state is RecordingRestored) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Recording restored'),
                  backgroundColor: Colors.green,
                ),
              );
            } else if (state is RecordingHardDeleted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Recording permanently deleted'),
                  backgroundColor: Colors.grey,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is SummaryLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            List<Recording> recordings = [];
            if (state is TrashedRecordingsLoaded) {
              recordings = state.recordings;
            } else if (state is SummaryLoaded || state is SummariesListLoaded) {
              return const Center(child: CircularProgressIndicator());
            }

            if (recordings.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.delete_outline,
                      size: 64,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Trash is empty',
                      style: TextStyle(color: Colors.grey[400], fontSize: 16),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: recordings.length,
              itemBuilder: (context, index) {
                final recording = recordings[index];

                return Card(
                  color: const Color(0xFF1F2937),
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(
                      recording.title.isEmpty ? 'Untitled' : recording.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      "${recording.createdAt.year}-${recording.createdAt.month.toString().padLeft(2, '0')}-${recording.createdAt.day.toString().padLeft(2, '0')}", // Simple date formatting
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.more_vert, color: Colors.white70),
                      onPressed: () => _showOptions(recording),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
