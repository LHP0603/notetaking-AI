import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/recording.dart';
import '../entities/upload_job.dart';

abstract class RecordingRepository {
  /// Start recording audio
  Future<Either<Failure, void>> startRecording();

  /// Stop recording and return the recording entity
  Future<Either<Failure, Recording>> stopRecording();

  /// Pause the current recording
  Future<Either<Failure, void>> pauseRecording();

  /// Resume the paused recording
  Future<Either<Failure, void>> resumeRecording();

  /// Import an audio file from device storage
  Future<Either<Failure, File>> importAudioFile();

  /// Upload recording asynchronously and get job info
  Future<Either<Failure, UploadJob>> uploadRecordingAsync(File audioFile);

  /// Get the current recording status
  RecordingStatus getRecordingStatus();

  /// Get the current recording duration stream
  Stream<Duration> get durationStream;
}




