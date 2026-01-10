import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/recording.dart';
import '../models/recording_model.dart';

abstract class RecordingLocalDataSource {
  Future<void> startRecording();
  Future<RecordingModel> stopRecording();
  Future<void> pauseRecording();
  Future<void> resumeRecording();
  Future<File> importAudioFile();
  LocalRecordingState getRecordingStatus();
  Stream<Duration> get durationStream;
  void dispose();
}

class RecordingLocalDataSourceImpl implements RecordingLocalDataSource {
  final AudioRecorder _recorder;
  LocalRecordingState _status = LocalRecordingState.idle;
  Timer? _durationTimer;
  Duration _currentDuration = Duration.zero;
  final StreamController<Duration> _durationController =
      StreamController<Duration>.broadcast();
  String? _currentFilePath;

  RecordingLocalDataSourceImpl({AudioRecorder? recorder})
      : _recorder = recorder ?? AudioRecorder();

  @override
  Stream<Duration> get durationStream => _durationController.stream;

  @override
  LocalRecordingState getRecordingStatus() => _status;

  @override
  Future<void> startRecording() async {
    try {
      // Check and request permission
      if (await _recorder.hasPermission()) {
        // Get the app's documents directory
        final directory = await getApplicationDocumentsDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        _currentFilePath = '${directory.path}/recording_$timestamp.m4a';

        // Configure recording
        const config = RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        );

        await _recorder.start(config, path: _currentFilePath!);
        _status = LocalRecordingState.recording;
        _currentDuration = Duration.zero;

        // Start duration timer
        _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          _currentDuration += const Duration(seconds: 1);
          _durationController.add(_currentDuration);
        });
      } else {
        throw const ServerException('Microphone permission denied');
      }
    } catch (e) {
      throw ServerException('Failed to start recording: $e');
    }
  }

  @override
  Future<RecordingModel> stopRecording() async {
    try {
      final path = await _recorder.stop();
      _durationTimer?.cancel();
      _status = LocalRecordingState.completed;

      final file = File(path ?? _currentFilePath ?? '');
      final fileSizeBytes = await file.length();
      final fileSizeMb = fileSizeBytes / (1024 * 1024);
      final fileName = path?.split('/').last ?? 'recording.m4a';
      final title = fileName.replaceAll('.m4a', '').replaceAll('.mp3', '').replaceAll('_', ' ');

      final recording = RecordingModel(
        recordingId: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: 'user_001', // TODO: Get from current user
        folderId: null, // TODO: Get from selected folder
        title: title,
        filePath: path ?? _currentFilePath ?? '',
        durationSeconds: _currentDuration.inSeconds.toDouble(),
        fileSizeMb: fileSizeMb,
        status: RecordingStatus.uploading, // New recording needs to be uploaded
        sourceType: SourceType.recorded,
        isPinned: false,
        isTrashed: false,
        originalFileName: fileName,
        lastPlayPosition: null,
        createdAt: DateTime.now(),
        deletedAt: null,
      );

      _currentDuration = Duration.zero;
      _currentFilePath = null;

      return recording;
    } catch (e) {
      throw ServerException('Failed to stop recording: $e');
    }
  }

  @override
  Future<void> pauseRecording() async {
    try {
      await _recorder.pause();
      _durationTimer?.cancel();
      _status = LocalRecordingState.paused;
    } catch (e) {
      throw ServerException('Failed to pause recording: $e');
    }
  }

  @override
  Future<void> resumeRecording() async {
    try {
      await _recorder.resume();
      _status = LocalRecordingState.recording;

      // Resume duration timer
      _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _currentDuration += const Duration(seconds: 1);
        _durationController.add(_currentDuration);
      });
    } catch (e) {
      throw ServerException('Failed to resume recording: $e');
    }
  }

  @override
  Future<File> importAudioFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        return File(result.files.single.path!);
      } else {
        throw const ServerException('No file selected');
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Failed to import audio file: $e');
    }
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    _durationController.close();
    _recorder.dispose();
  }
}










