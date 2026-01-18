# Audio Detail Screen - API Integration Guide

## Overview
This document provides implementation instructions for integrating the Audio Detail Screen with backend APIs. This includes loading audio details, menu actions (rename, delete, download), transcription management, and summary management.

## API Endpoints Summary

| Action | Method | Endpoint | Purpose |
|--------|--------|----------|---------|
| Get Audio Details | GET | `/audio/files/{audio_id}` | Load audio file information |
| Update Audio | PUT | `/audio/{audio_id}` | Rename audio or update transcription |
| Delete Audio | DELETE | `/audio/files/{audio_id}` | Delete audio file |
| Download Audio | GET | `/audio/files/{audio_id}/download` | Download audio file |
| Search Tasks | POST | `/tasks/search` | Check active transcription/summarization tasks |
| Start Transcription | POST | `/transcript/transcribe-async` | Trigger async transcription |
| Get Summary | POST | `/notes/search` | Retrieve audio summary (note) |
| Start Summarization | POST | `/notes/summarize-transcript-async` | Trigger async summarization |

## Implementation Details

### 1. Load Audio Details on Screen Open

#### Endpoint
```
GET /audio/files/{audio_id}
```

#### When to Call
When user taps the chevron right button and navigates to the Audio Detail Screen.

#### Response
```json
{
  "code": 200,
  "success": true,
  "message": "AUDIO_RETRIEVED_SUCCESS",
  "data": {
    "filename": "2_f696db066c524ae0bc11c58c9ddf0bfd.mp3",
    "original_filename": "videoplayback.mp3",
    "file_size": 716309,
    "duration": 44.747755,
    "format": "mp3",
    "id": 7,
    "user_id": 2,
    "file_path": "uploads/audio/2_f696db066c524ae0bc11c58c9ddf0bfd.mp3",
    "status": "completed",
    "transcription": "Một nghiên cứu mới cho thấy...",
    "confidence_score": 0.9473274946212769,
    "created_at": "2025-12-15T18:21:29.931959",
    "updated_at": "2025-12-15T18:22:02.861872",
    "is_summarize": true
  }
}
```

#### Implementation

**Data Source Method**:
```dart
Future<AudioFile> getAudioFileById(int audioId) async {
  try {
    final response = await dio.get(
      '${AppConstants.baseUrl}/audio/files/$audioId',
    );

    final data = _extractData(
      response,
      fallbackMessage: 'Failed to load audio details',
    );

    return AudioFile.fromJson(data);
  } on DioException catch (e) {
    throw _handleDioException(e, fallbackMessage: 'Failed to load audio details');
  }
}
```

**Screen Integration**:
```dart
class _AudioDetailScreenState extends State<AudioDetailScreen> {
  AudioFile? _audioFile;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAudioDetails();
  }

  Future<void> _loadAudioDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final audioFile = await context
          .read<AudioManagerBloc>()
          .repository
          .getAudioFileById(widget.audioFile.id);
      
      setState(() {
        _audioFile = audioFile;
        _isLoading = false;
      });
      
      // Start polling for active tasks
      _startTaskPolling();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }
}
```

### 2. Rename Audio

#### Endpoint
```
PUT /audio/{audio_id}
```

#### Request Payload
```json
{
  "original_filename": "New Audio Name"
}
```

**Note**: Only send `original_filename` field for rename operation. The `transcription` field is for updating transcript.

#### Response
```json
{
  "code": 200,
  "success": true,
  "message": "AUDIO_UPDATED_SUCCESS",
  "data": {
    "filename": "New Audio Name.mp3",
    "original_filename": "New Audio Name",
    "file_size": 716309,
    "duration": 44.747755,
    "format": "mp3",
    "id": 7,
    "user_id": 2,
    "file_path": "uploads/audio/2_f696db066c524ae0bc11c58c9ddf0bfd.mp3",
    "status": "completed",
    "transcription": "...",
    "confidence_score": 0.9473274946212769,
    "created_at": "2025-12-15T18:21:29.931959",
    "updated_at": "2025-12-26T11:27:03.282308",
    "is_summarize": true
  }
}
```

#### Implementation

**Data Source Method**:
```dart
Future<AudioFile> renameAudio(int audioId, String newName) async {
  try {
    final response = await dio.put(
      '${AppConstants.baseUrl}/audio/$audioId',
      data: {'original_filename': newName},
    );

    final data = _extractData(
      response,
      fallbackMessage: 'Failed to rename audio',
    );

    return AudioFile.fromJson(data);
  } on DioException catch (e) {
    throw _handleDioException(e, fallbackMessage: 'Failed to rename audio');
  }
}
```

**UI Integration**:
```dart
void _showRenameDialog() {
  final controller = TextEditingController(
    text: _audioFile?.originalFilename ?? '',
  );
  
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Rename Audio'),
      content: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: 'New filename',
          border: OutlineInputBorder(),
        ),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            final newName = controller.text.trim();
            if (newName.isNotEmpty && _audioFile != null) {
              Navigator.pop(context);
              await _handleRename(newName);
            }
          },
          child: Text('Rename'),
        ),
      ],
    ),
  );
}

Future<void> _handleRename(String newName) async {
  try {
    final updatedAudio = await context
        .read<AudioManagerBloc>()
        .repository
        .renameAudio(_audioFile!.id, newName);
    
    setState(() {
      _audioFile = updatedAudio;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Audio renamed successfully')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to rename audio: $e')),
    );
  }
}
```

### 3. Delete Audio

#### Endpoint
```
DELETE /audio/files/{audio_id}
```

#### Response
```json
{
  "code": 200,
  "success": true,
  "message": "AUDIO_DELETED_SUCCESS",
  "data": null
}
```

#### Implementation

**Data Source Method**:
```dart
Future<void> deleteAudio(int audioId) async {
  try {
    final response = await dio.delete(
      '${AppConstants.baseUrl}/audio/files/$audioId',
    );

    final payload = response.data;
    if (payload is! Map<String, dynamic>) {
      throw ServerException('Invalid response format');
    }

    if (payload['success'] != true) {
      final message = payload['message']?.toString() ?? 'Failed to delete audio';
      throw ServerException(message);
    }
  } on DioException catch (e) {
    throw _handleDioException(e, fallbackMessage: 'Failed to delete audio');
  }
}
```

**UI Integration**:
```dart
void _showDeleteConfirmation() {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Delete Audio'),
      content: Text(
        'Are you sure you want to delete this audio? This action cannot be undone.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(context); // Close dialog
            await _handleDelete();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
          ),
          child: Text('Delete'),
        ),
      ],
    ),
  );
}

Future<void> _handleDelete() async {
  if (_audioFile == null) return;
  
  try {
    await context
        .read<AudioManagerBloc>()
        .repository
        .deleteAudio(_audioFile!.id);
    
    Navigator.pop(context); // Go back to previous screen
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Audio deleted successfully')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to delete audio: $e')),
    );
  }
}
```

### 4. Download Audio

#### Endpoint
```
GET /audio/files/{audio_id}/download
```

#### Response
- **Success**: Binary file data (FileResponse)
- **Error**:
```json
{
  "code": 404,
  "success": false,
  "message": "AUDIO_FILE_NOT_FOUND_ON_DISK",
  "data": null
}
```

#### Implementation

**Data Source Method**:
```dart
Future<void> downloadAudio(int audioId, String filename) async {
  try {
    final response = await dio.get(
      '${AppConstants.baseUrl}/audio/files/$audioId/download',
      options: Options(
        responseType: ResponseType.bytes,
      ),
    );

    // Save file to device
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/$filename';
    final file = File(filePath);
    await file.writeAsBytes(response.data);
    
    // Optionally open/share the file
    // await OpenFile.open(filePath);
  } on DioException catch (e) {
    if (e.response?.data is Map) {
      final data = e.response!.data as Map<String, dynamic>;
      final message = data['message']?.toString() ?? 'File not found';
      throw ServerException(message);
    }
    throw _handleDioException(e, fallbackMessage: 'Failed to download audio');
  }
}
```

**UI Integration**:
```dart
Future<void> _handleDownload() async {
  if (_audioFile == null) return;
  
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Downloading audio...')),
  );
  
  try {
    await context
        .read<AudioManagerBloc>()
        .repository
        .downloadAudio(
          _audioFile!.id,
          _audioFile!.originalFilename ?? _audioFile!.filename ?? 'audio.mp3',
        );
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Audio downloaded successfully')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to download audio: $e')),
    );
  }
}
```

### 5. Task Polling for Progress Tracking

#### Endpoint
```
POST /tasks/search
```

#### Request Payload
```json
{
  "active_only": true,
  "audio_id": 12,
  "order": "DESC",
  "page": 1,
  "page_size": 10
}
```

**Fields**:
- `active_only`: true - Only get active tasks
- `audio_id`: Current audio ID
- `order`: "DESC" - Newest first
- `page`: 1
- `page_size`: 10

#### Response
```json
{
  "code": 200,
  "success": true,
  "message": "Tasks retrieved successfully",
  "data": {
    "data": [
      {
        "id": "9348a993-adaf-48fa-95dc-6d2a9b574357",
        "task_type": "summarize",
        "status": "processing",
        "result": null,
        "error_message": null,
        "audio_id": 12,
        "metadata_json": null,
        "created_at": "2025-12-26T14:10:02.779395",
        "updated_at": "2025-12-26T14:10:03.165469"
      }
    ],
    "meta": {
      "page": 1,
      "page_size": 10,
      "item_count": 1,
      "page_count": 1,
      "has_previous_page": false,
      "has_next_page": false
    }
  }
}
```

#### Polling Logic

**When to Show Loading State**:
- `task_type` is `"transcribe"` AND `status` is one of: `"pending"`, `"queued"`, `"processing"`
- `task_type` is `"summarize"` AND `status` is one of: `"pending"`, `"queued"`, `"processing"`

**Polling Behavior**:
- Poll every **5 seconds**
- Stop polling when:
  - User exits the screen
  - Task `status` becomes `"completed"`
  - Task `status` becomes `"failed"`
  - No active tasks found

#### Implementation

**Data Source Method**:
```dart
Future<List<TaskModel>> getActiveTasks(int audioId) async {
  try {
    final response = await dio.post(
      '${AppConstants.baseUrl}/tasks/search',
      data: {
        'active_only': true,
        'audio_id': audioId,
        'order': 'DESC',
        'page': 1,
        'page_size': 10,
      },
    );

    final data = _extractData(
      response,
      fallbackMessage: 'Failed to load tasks',
    );

    final taskItems = data['data'];
    if (taskItems is! List) {
      throw const ServerException('Invalid response data');
    }

    return taskItems
        .map((item) => TaskModel.fromJson(item as Map<String, dynamic>))
        .toList();
  } on DioException catch (e) {
    throw _handleDioException(e, fallbackMessage: 'Failed to load tasks');
  }
}
```

**Task Model**:
```dart
class TaskModel {
  final String id;
  final String taskType; // "transcribe" or "summarize"
  final String status; // "pending", "queued", "processing", "completed", "failed"
  final dynamic result;
  final String? errorMessage;
  final int audioId;
  final Map<String, dynamic>? metadataJson;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TaskModel({
    required this.id,
    required this.taskType,
    required this.status,
    this.result,
    this.errorMessage,
    required this.audioId,
    this.metadataJson,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] as String,
      taskType: json['task_type'] as String,
      status: json['status'] as String,
      result: json['result'],
      errorMessage: json['error_message'] as String?,
      audioId: json['audio_id'] as int,
      metadataJson: json['metadata_json'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  bool get isTranscribing => 
      taskType == 'transcribe' && 
      ['pending', 'queued', 'processing'].contains(status);

  bool get isSummarizing => 
      taskType == 'summarize' && 
      ['pending', 'queued', 'processing'].contains(status);

  bool get isCompleted => status == 'completed';
  bool get isFailed => status == 'failed';
}
```

**Polling Implementation in Screen**:
```dart
class _AudioDetailScreenState extends State<AudioDetailScreen> {
  Timer? _taskPollingTimer;
  List<TaskModel> _activeTasks = [];
  
  bool get _isTranscribing {
    return _activeTasks.any((task) => task.isTranscribing);
  }
  
  bool get _isSummarizing {
    return _activeTasks.any((task) => task.isSummarizing);
  }

  @override
  void initState() {
    super.initState();
    _loadAudioDetails();
  }

  void _startTaskPolling() {
    _pollTasks(); // Poll immediately
    _taskPollingTimer = Timer.periodic(Duration(seconds: 5), (_) {
      _pollTasks();
    });
  }

  Future<void> _pollTasks() async {
    if (_audioFile == null) return;
    
    try {
      final tasks = await context
          .read<AudioManagerBloc>()
          .repository
          .getActiveTasks(_audioFile!.id);
      
      setState(() {
        _activeTasks = tasks;
      });

      // Stop polling if all tasks are completed or failed
      final hasActiveTasks = tasks.any(
        (task) => !task.isCompleted && !task.isFailed,
      );
      
      if (!hasActiveTasks) {
        _stopTaskPolling();
        // Reload audio details to get updated transcription/summary
        _loadAudioDetails();
      }
    } catch (e) {
      print('Failed to poll tasks: $e');
    }
  }

  void _stopTaskPolling() {
    _taskPollingTimer?.cancel();
    _taskPollingTimer = null;
  }

  @override
  void dispose() {
    _stopTaskPolling();
    super.dispose();
  }
}
```

### 6. Transcription Tab

#### Display Transcription
Use the `transcription` field from the audio details API response.

#### Save Transcription

**Endpoint**: `PUT /audio/{audio_id}`

**Request Payload**:
```json
{
  "transcription": "Updated transcription text here..."
}
```

**Implementation**:
```dart
Future<AudioFile> updateTranscription(int audioId, String transcription) async {
  try {
    final response = await dio.put(
      '${AppConstants.baseUrl}/audio/$audioId',
      data: {'transcription': transcription},
    );

    final data = _extractData(
      response,
      fallbackMessage: 'Failed to update transcription',
    );

    return AudioFile.fromJson(data);
  } on DioException catch (e) {
    throw _handleDioException(e, fallbackMessage: 'Failed to update transcription');
  }
}
```

**UI Integration**:
```dart
Future<void> _handleSaveTranscription(String transcription) async {
  if (_audioFile == null) return;
  
  try {
    final updatedAudio = await context
        .read<AudioManagerBloc>()
        .repository
        .updateTranscription(_audioFile!.id, transcription);
    
    setState(() {
      _audioFile = updatedAudio;
      _initialTranscription = transcription;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Transcription saved successfully')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to save transcription: $e')),
    );
  }
}
```

#### Start Transcription

**Endpoint**: `POST /transcript/transcribe-async`

**Request Payload**:
```json
{
  "audio_id": 7,
  "language_code": "vi-VN"
}
```

**Always set `language_code` to `"vi-VN"`**

**Response**:
```json
{
  "code": 200,
  "success": true,
  "message": "Task queued successfully. Use job_id to check status.",
  "data": {
    "job_id": "5ef29e14-d0f8-4089-85ce-4768991377d5",
    "task_type": "transcribe",
    "status": "queued"
  }
}
```

**Implementation**:
```dart
Future<void> startTranscription(int audioId) async {
  try {
    final response = await dio.post(
      '${AppConstants.baseUrl}/transcript/transcribe-async',
      data: {
        'audio_id': audioId,
        'language_code': 'vi-VN',
      },
    );

    final data = _extractData(
      response,
      fallbackMessage: 'Failed to start transcription',
    );

    // Optionally return job info
    return;
  } on DioException catch (e) {
    throw _handleDioException(e, fallbackMessage: 'Failed to start transcription');
  }
}
```

**UI Integration**:
```dart
Future<void> _handleStartTranscription() async {
  if (_audioFile == null) return;
  
  try {
    await context
        .read<AudioManagerBloc>()
        .repository
        .startTranscription(_audioFile!.id);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Transcription started. Please wait...')),
    );
    
    // Start polling to track progress
    _startTaskPolling();
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to start transcription: $e')),
    );
  }
}
```

**Transcription Tab State Logic**:
```dart
Widget build(BuildContext context) {
  if (_isTranscribing) {
    return _buildTranscribingView();
  }
  
  if (!_hasTranscription) {
    return _buildNoTranscriptionView();
  }
  
  return _buildTranscriptionEditor();
}

Widget _buildTranscribingView() {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(),
        SizedBox(height: 24),
        Text(
          'Transcribing Audio...',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 12),
        Text('Please wait while we transcribe your audio.'),
      ],
    ),
  );
}
```

### 7. Summary Tab

#### Get Summary (Note)

**Endpoint**: `POST /notes/search`

**Request Payload**:
```json
{
  "audio_file_id": 7,
  "page": 1,
  "page_size": 1
}
```

**Response**:
```json
{
  "code": 200,
  "success": true,
  "message": "Notes retrieved successfully",
  "data": {
    "data": [
      {
        "title": "videoplayback",
        "content": "Full transcript content...",
        "summary": "<article lang=\"vi\">\n  <section>\n    <p>Summary content in HTML format...</p>\n  </section>\n</article>",
        "category": "transcription",
        "priority": "normal",
        "is_favorite": false,
        "color": "#FFFFFF",
        "tags": "audio,transcription",
        "audio_timestamp": null,
        "audio_transcript_excerpt": null,
        "is_shared": false,
        "id": 3,
        "user_id": 2,
        "audio_file_id": 2,
        "is_archived": false,
        "shared_with": null,
        "created_at": "2025-12-04T18:37:50.161937",
        "updated_at": "2025-12-04T18:37:50.161941"
      }
    ],
    "meta": {
      "page": 1,
      "page_size": 1,
      "item_count": 3,
      "page_count": 3,
      "has_previous_page": false,
      "has_next_page": true
    }
  }
}
```

**Note**: Take the **first note** from the `data` array (index 0), as the BE relationship between Note and Audio is incorrectly configured (should be 1-1).

**Implementation**:
```dart
Future<NoteModel?> getSummaryNote(int audioFileId) async {
  try {
    final response = await dio.post(
      '${AppConstants.baseUrl}/notes/search',
      data: {
        'audio_file_id': audioFileId,
        'page': 1,
        'page_size': 1,
      },
    );

    final data = _extractData(
      response,
      fallbackMessage: 'Failed to load summary',
    );

    final notes = data['data'] as List;
    if (notes.isEmpty) {
      return null;
    }

    return NoteModel.fromJson(notes[0] as Map<String, dynamic>);
  } on DioException catch (e) {
    throw _handleDioException(e, fallbackMessage: 'Failed to load summary');
  }
}
```

**Note Model**:
```dart
class NoteModel {
  final int id;
  final String title;
  final String content;
  final String? summary; // HTML format
  final String category;
  final String priority;
  final bool isFavorite;
  final String color;
  final String? tags;
  final int audioFileId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const NoteModel({
    required this.id,
    required this.title,
    required this.content,
    this.summary,
    required this.category,
    required this.priority,
    required this.isFavorite,
    required this.color,
    this.tags,
    required this.audioFileId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NoteModel.fromJson(Map<String, dynamic> json) {
    return NoteModel(
      id: json['id'] as int,
      title: json['title'] as String,
      content: json['content'] as String,
      summary: json['summary'] as String?,
      category: json['category'] as String,
      priority: json['priority'] as String,
      isFavorite: json['is_favorite'] as bool,
      color: json['color'] as String,
      tags: json['tags'] as String?,
      audioFileId: json['audio_file_id'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}
```

**UI Integration**:
```dart
NoteModel? _summaryNote;

@override
void initState() {
  super.initState();
  _loadSummary();
}

Future<void> _loadSummary() async {
  if (_audioFile == null || !_audioFile!.isSummarize) return;
  
  try {
    final note = await context
        .read<AudioManagerBloc>()
        .repository
        .getSummaryNote(_audioFile!.id);
    
    setState(() {
      _summaryNote = note;
    });
  } catch (e) {
    print('Failed to load summary: $e');
  }
}
```

#### Start Summarization

**Endpoint**: `POST /notes/summarize-transcript-async`

**Request Payload**:
```json
{
  "audio_file_id": 7
}
```

**Response**:
```json
{
  "code": 200,
  "success": true,
  "message": "Task queued successfully. Use job_id to check status.",
  "data": {
    "job_id": "89c5c769-d72a-4926-9ba4-faff343519c8",
    "task_type": "summarize",
    "status": "queued"
  }
}
```

**Implementation**:
```dart
Future<void> startSummarization(int audioFileId) async {
  try {
    final response = await dio.post(
      '${AppConstants.baseUrl}/notes/summarize-transcript-async',
      data: {
        'audio_file_id': audioFileId,
      },
    );

    final data = _extractData(
      response,
      fallbackMessage: 'Failed to start summarization',
    );

    return;
  } on DioException catch (e) {
    throw _handleDioException(e, fallbackMessage: 'Failed to start summarization');
  }
}
```

**UI Integration**:
```dart
Future<void> _handleStartSummarization() async {
  if (_audioFile == null) return;
  
  try {
    await context
        .read<AudioManagerBloc>()
        .repository
        .startSummarization(_audioFile!.id);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Summarization started. Please wait...')),
    );
    
    // Start polling to track progress
    _startTaskPolling();
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to start summarization: $e')),
    );
  }
}
```

**Summary Tab State Logic**:
```dart
Widget build(BuildContext context) {
  if (_isSummarizing) {
    return _buildSummarizingView();
  }
  
  if (!_audioFile.isSummarize || _summaryNote == null) {
    return _buildNoSummaryView();
  }
  
  return _buildSummaryEditor();
}

Widget _buildSummarizingView() {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(),
        SizedBox(height: 24),
        Text(
          'Generating Summary...',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 12),
        Text('Please wait while we generate a summary.'),
      ],
    ),
  );
}
```

### 8. Success/Error Handling

**Success Condition**: `success === true` in response

**Error Condition**: `success !== true` in response

**Implementation**:
```dart
dynamic _extractData(
  Response<dynamic> response, {
  required String fallbackMessage,
}) {
  final payload = response.data;
  if (payload is! Map<String, dynamic>) {
    throw ServerException('Invalid response format');
  }

  final success = payload['success'] == true;
  if (!success) {
    final message = payload['message']?.toString() ?? fallbackMessage;
    final code = payload['code'] is int ? payload['code'] as int : 500;
    throw ServerException(message, code: code);
  }

  return payload['data'];
}
```

## App Constants

Add new endpoint constants:

```dart
class AppConstants {
  static const String baseUrl = 'YOUR_BASE_URL';
  
  // Existing endpoints...
  
  // Audio endpoints
  static String audioFileById(int id) => '/audio/files/$id';
  static String updateAudio(int id) => '/audio/$id';
  static String deleteAudio(int id) => '/audio/files/$id';
  static String downloadAudio(int id) => '/audio/files/$id/download';
  
  // Task endpoints
  static const String searchTasks = '/tasks/search';
  
  // Transcription endpoints
  static const String transcribeAsync = '/transcript/transcribe-async';
  
  // Note/Summary endpoints
  static const String searchNotes = '/notes/search';
  static const String summarizeAsync = '/notes/summarize-transcript-async';
}
```

## Implementation Checklist

### Data Layer
- [ ] Add `getAudioFileById` method to remote data source
- [ ] Add `renameAudio` method to remote data source
- [ ] Add `deleteAudio` method to remote data source
- [ ] Add `downloadAudio` method to remote data source
- [ ] Add `getActiveTasks` method to remote data source
- [ ] Add `updateTranscription` method to remote data source
- [ ] Add `startTranscription` method to remote data source
- [ ] Add `getSummaryNote` method to remote data source
- [ ] Add `startSummarization` method to remote data source
- [ ] Create `TaskModel` entity
- [ ] Create `NoteModel` entity
- [ ] Add endpoint constants to AppConstants

### Screen Integration
- [ ] Load audio details on screen open
- [ ] Implement rename functionality with API
- [ ] Implement delete functionality with API
- [ ] Implement download functionality with API
- [ ] Implement task polling (every 5 seconds)
- [ ] Stop polling on screen exit or task completion
- [ ] Show loading state for transcribing tasks
- [ ] Show loading state for summarizing tasks
- [ ] Reload audio details after task completion

### Transcription Tab
- [ ] Display transcription from API
- [ ] Save transcription updates to API
- [ ] Start transcription with vi-VN language code
- [ ] Show "transcribing" state during processing
- [ ] Disable/enable UI based on task status

### Summary Tab
- [ ] Load summary note from API when tab opens
- [ ] Display summary in flutter_quill editor
- [ ] Start summarization when button clicked
- [ ] Show "summarizing" state during processing
- [ ] Reload summary after task completion
- [ ] Disable tab when no transcript exists

### Error Handling
- [ ] Handle network errors gracefully
- [ ] Show user-friendly error messages
- [ ] Implement retry logic where appropriate
- [ ] Handle file not found errors for download

## Testing Checklist

- [ ] Test loading audio details on screen open
- [ ] Test rename with valid and invalid names
- [ ] Test delete with confirmation
- [ ] Test download success and error cases
- [ ] Test task polling starts and stops correctly
- [ ] Test transcription start and progress tracking
- [ ] Test transcription save
- [ ] Test summarization start and progress tracking
- [ ] Test summary display with HTML content
- [ ] Test polling stops after task completion
- [ ] Test polling stops when user exits screen
- [ ] Test error handling for all API calls
- [ ] Test success messages display correctly

## Notes

- Always check `success === true` to determine if API call succeeded
- Use `vi-VN` as default language code for transcription
- Poll tasks every 5 seconds until completion or screen exit
- Take first note from notes/search response (array index 0)
- Summary content is in HTML format, compatible with flutter_quill
- Handle both network errors and API errors appropriately
- Consider adding retry logic for failed API calls
- Consider caching audio details to reduce API calls
