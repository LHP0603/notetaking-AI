import 'dart:io';
import 'package:dartz/dartz.dart' hide Task;
import '../../../../core/errors/failures.dart';
import '../entities/audio_file.dart';
import '../entities/audio_file_page.dart';
import '../entities/audio_filter.dart';
import '../entities/audio_upload_result.dart';
import '../entities/note.dart';
import '../entities/server_task_bucket.dart';
import '../entities/pending_task_bucket.dart';
import '../entities/task.dart';
import '../entities/task_search_criteria.dart';

abstract class AudioManagerRepository {
  Future<Either<Failure, AudioFilePage>> getUploadedAudios(
    AudioFilter filter,
  );
  Future<Either<Failure, AudioFile>> getAudioFileById(int audioId);
  Future<Either<Failure, AudioUploadResult>> uploadAudioFile(File audioFile);
  Future<Either<Failure, AudioFile>> renameAudio(int audioId, String newName);
  Future<Either<Failure, bool>> deleteAudio(int audioId);
  Future<Either<Failure, String>> downloadAudio(int audioId, String filename);
  Future<Either<Failure, List<Task>>> getActiveTasks(int audioId);
  Future<Either<Failure, AudioFile>> updateTranscription(
    int audioId,
    String transcription,
  );
  Future<Either<Failure, bool>> startTranscription(int audioId);
  Future<Either<Failure, Note?>> getSummaryNote(int audioFileId);
  Future<Either<Failure, Note>> getNoteById(int noteId);
  Future<Either<Failure, bool>> startSummarization(int audioFileId);
  Future<Either<Failure, Note>> updateNoteSummary(int noteId, String summary);
  Future<Either<Failure, ServerTaskBucket>> getServerTasks();
  Future<Either<Failure, PendingTaskBucket>> getPendingTasks();
  Future<Either<Failure, List<Task>>> searchTasks(
    TaskSearchCriteria criteria,
  );
}
