import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../injection_container/injection_container.dart';
import '../../domain/entities/audio_file.dart';
import '../../domain/entities/note.dart';
import '../../domain/entities/task.dart';
import '../../domain/repositories/audio_manager_repository.dart';
import 'summary_tab.dart';
import 'transcription_tab.dart';

enum AudioMenuAction { rename, delete, download }

class AudioDetailScreen extends StatefulWidget {
  final AudioFile audioFile;

  const AudioDetailScreen({super.key, required this.audioFile});

  @override
  State<AudioDetailScreen> createState() => _AudioDetailScreenState();
}

class _AudioDetailScreenState extends State<AudioDetailScreen>
    with SingleTickerProviderStateMixin {
  final AudioManagerRepository _repository = sl<AudioManagerRepository>();
  late final TabController _tabController;

  AudioFile? _audioFile;
  Note? _summaryNote;
  Timer? _taskPollingTimer;
  List<Task> _activeTasks = [];
  bool _hadActiveTasks = false;
  bool _isWaitingForTranscription = false;
  bool _isWaitingForSummarization = false;
  bool _isLoading = true;
  String? _errorMessage;
  bool _transcriptDirty = false;
  bool _summaryDirty = false;

  bool get _hasTranscript {
    final text = _audioFile?.transcription;
    return text != null && text.trim().isNotEmpty;
  }

  bool get _hasSummary {
    if (_summaryNote != null) {
      return true;
    }
    final summaryText = _audioFile?.summary;
    return summaryText != null && summaryText.trim().isNotEmpty;
  }

  bool get _isTranscribing {
    return _activeTasks.any((task) => task.isTranscribing) ||
        _isWaitingForTranscription;
  }

  bool get _isSummarizing {
    return _activeTasks.any((task) => task.isSummarizing) ||
        _isWaitingForSummarization;
  }

  bool get _hasUnsavedChanges => _transcriptDirty || _summaryDirty;

  @override
  void initState() {
    super.initState();
    _audioFile = widget.audioFile;
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChanged);
    _loadAudioDetails();
  }

  @override
  void dispose() {
    _stopTaskPolling();
    _tabController.removeListener(_handleTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChanged() {
    if (_tabController.index == 1 && !_hasTranscript) {
      _tabController.index = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please transcribe the audio first'),
          ),
        );
      });
    }
  }

  Future<void> _loadAudioDetails({bool startPolling = true}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _repository.getAudioFileById(widget.audioFile.id);
    if (!mounted) {
      return;
    }

    await result.fold(
      (failure) async {
        setState(() {
          _isLoading = false;
          _errorMessage = failure.message;
        });
      },
      (audioFile) async {
        setState(() {
          _audioFile = audioFile;
          _isLoading = false;
        });
        await _loadSummary();
        if (startPolling) {
          _startTaskPolling();
        }
      },
    );
  }

  Future<void> _loadSummary() async {
    final audioFile = _audioFile;
    if (audioFile == null) {
      return;
    }

    final shouldLoad = audioFile.isSummarize == true ||
        audioFile.hasSummary == true ||
        audioFile.summary != null;
    if (!shouldLoad) {
      if (mounted) {
        setState(() {
          _summaryNote = null;
        });
      }
      return;
    }

    final result = await _repository.getSummaryNote(audioFile.id);
    if (!mounted) {
      return;
    }

    result.fold(
      (_) {},
      (note) {
        setState(() {
          _summaryNote = note;
        });
      },
    );
  }

  void _startTaskPolling() {
    _stopTaskPolling();
    _pollTasks();
    _taskPollingTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _pollTasks(),
    );
  }

  Future<void> _pollTasks() async {
    final audioFile = _audioFile;
    if (audioFile == null) {
      return;
    }

    final result = await _repository.getActiveTasks(audioFile.id);
    if (!mounted) {
      return;
    }

    result.fold(
      (_) {},
      (tasks) {
        final hasActiveTasks = tasks.any((task) => task.isActive);
        final hasTranscribeActive =
            tasks.any((task) => task.isTranscribing);
        final hasSummarizeActive =
            tasks.any((task) => task.isSummarizing);

        setState(() {
          _activeTasks = tasks;
          if (hasTranscribeActive) {
            _isWaitingForTranscription = false;
          }
          if (hasSummarizeActive) {
            _isWaitingForSummarization = false;
          }
        });

        if (hasActiveTasks) {
          _hadActiveTasks = true;
          return;
        }

        if (_isWaitingForTranscription || _isWaitingForSummarization) {
          return;
        }

        _stopTaskPolling();
        if (_hadActiveTasks) {
          _hadActiveTasks = false;
          _loadAudioDetails(startPolling: false);
        }
      },
    );
  }

  void _stopTaskPolling() {
    _taskPollingTimer?.cancel();
    _taskPollingTimer = null;
  }

  Future<bool> _handleBackPressed() async {
    if (!_hasUnsavedChanges) {
      return true;
    }
    final shouldExit = await _showUnsavedChangesDialog();
    return shouldExit ?? false;
  }

  Future<bool?> _showUnsavedChangesDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text(
          'You have unsaved changes. Do you want to save before leaving?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(AudioMenuAction action) {
    switch (action) {
      case AudioMenuAction.rename:
        _showRenameDialog();
        break;
      case AudioMenuAction.delete:
        _showDeleteConfirmation();
        break;
      case AudioMenuAction.download:
        _handleDownload();
        break;
    }
  }

  void _showRenameDialog() {
    final audioFile = _audioFile ?? widget.audioFile;
    final currentName = audioFile.originalFilename ?? audioFile.filename;
    final controller = TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Audio'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'New filename',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isEmpty) {
                return;
              }
              Navigator.pop(context);
              _handleRename(newName);
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleRename(String newName) async {
    final audioFile = _audioFile;
    if (audioFile == null) {
      return;
    }

    final result = await _repository.renameAudio(audioFile.id, newName);
    if (!mounted) {
      return;
    }

    result.fold(
      (failure) => _showSnackBar('Failed to rename audio: ${failure.message}'),
      (updatedAudio) {
        setState(() {
          _audioFile = updatedAudio;
        });
        _showSnackBar('Audio renamed successfully');
      },
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Audio'),
        content: const Text(
          'Are you sure you want to delete this audio? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(dialogContext);
              _handleDelete();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDelete() async {
    final audioFile = _audioFile;
    if (audioFile == null) {
      return;
    }

    final result = await _repository.deleteAudio(audioFile.id);
    if (!mounted) {
      return;
    }

    result.fold(
      (failure) => _showSnackBar('Failed to delete audio: ${failure.message}'),
      (_) {
        final messenger = ScaffoldMessenger.of(context);
        Navigator.pop(context);
        messenger.showSnackBar(
          const SnackBar(content: Text('Audio deleted successfully')),
        );
      },
    );
  }

  Future<void> _handleDownload() async {
    final audioFile = _audioFile;
    if (audioFile == null) {
      return;
    }

    _showSnackBar('Downloading audio...');

    final filename =
        audioFile.originalFilename ?? audioFile.filename ?? 'audio.mp3';
    final result = await _repository.downloadAudio(audioFile.id, filename);
    if (!mounted) {
      return;
    }

    result.fold(
      (failure) => _showSnackBar('Failed to download audio: ${failure.message}'),
      (_) => _showSnackBar('Audio downloaded successfully'),
    );
  }

  Future<String?> _handleSaveTranscription(String transcription) async {
    final audioFile = _audioFile;
    if (audioFile == null) {
      return 'Audio details are missing';
    }

    final result = await _repository.updateTranscription(
      audioFile.id,
      transcription,
    );
    if (!mounted) {
      return 'Audio details are no longer available';
    }

    String? errorMessage;
    result.fold(
      (failure) => errorMessage = failure.message,
      (updatedAudio) {
        setState(() {
          _audioFile = updatedAudio;
        });
      },
    );

    return errorMessage;
  }

  Future<String?> _handleStartTranscription() async {
    final audioFile = _audioFile;
    if (audioFile == null) {
      return 'Audio details are missing';
    }

    final result = await _repository.startTranscription(audioFile.id);
    if (!mounted) {
      return 'Audio details are no longer available';
    }

    String? errorMessage;
    result.fold(
      (failure) => errorMessage = failure.message,
      (_) {
        _isWaitingForTranscription = true;
        _startTaskPolling();
      },
    );

    return errorMessage;
  }

  Future<String?> _handleStartSummarization() async {
    final audioFile = _audioFile;
    if (audioFile == null) {
      return 'Audio details are missing';
    }

    final result = await _repository.startSummarization(audioFile.id);
    if (!mounted) {
      return 'Audio details are no longer available';
    }

    String? errorMessage;
    result.fold(
      (failure) => errorMessage = failure.message,
      (_) {
        _isWaitingForSummarization = true;
        _startTaskPolling();
      },
    );

    return errorMessage;
  }

  Future<String?> _handleSaveSummary(String summary) async {
    final summaryNote = _summaryNote;
    if (summaryNote == null) {
      return 'Summary note not available';
    }

    final result = await _repository.updateNoteSummary(summaryNote.id, summary);
    if (!mounted) {
      return 'Summary note is no longer available';
    }

    String? errorMessage;
    result.fold((failure) => errorMessage = failure.message, (updatedNote) {
      setState(() {
        _summaryNote = updatedNote;
      });
    });

    return errorMessage;
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadAudioDetails,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final audioFile = _audioFile ?? widget.audioFile;
    final title =
        audioFile.originalFilename ?? audioFile.filename ?? 'Audio Details';

    return WillPopScope(
      onWillPop: _handleBackPressed,
      child: Scaffold(
        backgroundColor: const Color(0xFF101822),
        appBar: AppBar(
          backgroundColor: const Color(0xFF101822),
          elevation: 0,
          title: Text(title, overflow: TextOverflow.ellipsis),
          leading: IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () async {
              final shouldPop = await _handleBackPressed();
              if (shouldPop && mounted) {
                Navigator.pop(context);
              }
            },
          ),
          actions: [
            PopupMenuButton<AudioMenuAction>(
              icon: const Icon(Icons.more_vert),
              onSelected: _handleMenuAction,
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: AudioMenuAction.rename,
                  child: Row(
                    children: [
                      Icon(Icons.edit),
                      SizedBox(width: 12),
                      Text('Rename Audio'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: AudioMenuAction.delete,
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 12),
                      Text('Delete Audio', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: AudioMenuAction.download,
                  child: Row(
                    children: [
                      Icon(Icons.download),
                      SizedBox(width: 12),
                      Text('Download Audio'),
                    ],
                  ),
                ),
              ],
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFF3B82F6),
            tabs: [
              const Tab(text: 'Transcription'),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Summary'),
                    if (!_hasTranscript) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.lock, size: 16),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        body: _errorMessage != null && !_isLoading
            ? _buildErrorState(_errorMessage!)
            : Column(
                children: [
                  if (_isLoading)
                    const LinearProgressIndicator(
                      backgroundColor: Color(0xFF101822),
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
                    ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      physics: _hasTranscript
                          ? null
                          : const NeverScrollableScrollPhysics(),
                      children: [
                        TranscriptionTab(
                          audioFile: audioFile,
                          hasTranscript: _hasTranscript,
                          isTranscribing: _isTranscribing,
                          onChanged: () =>
                              setState(() => _transcriptDirty = true),
                          onSaved: () =>
                              setState(() => _transcriptDirty = false),
                          onSaveTranscription: _handleSaveTranscription,
                          onStartTranscription: _handleStartTranscription,
                        ),
                        SummaryTab(
                            noteId: _summaryNote?.id,
                          summaryHtml: _summaryNote?.summary ?? audioFile.summary,
                          hasSummary: _hasSummary,
                          enabled: _hasTranscript,
                          isSummarizing: _isSummarizing,
                          onChanged: () =>
                              setState(() => _summaryDirty = true),
                          onSaved: () =>
                              setState(() => _summaryDirty = false),
                          onStartSummarization: _handleStartSummarization,
                            onSaveSummary: _handleSaveSummary,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
