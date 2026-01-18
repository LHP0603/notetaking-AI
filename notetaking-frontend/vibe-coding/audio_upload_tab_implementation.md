# Audio Upload Tab Implementation Guide

## Overview
This document provides implementation instructions for the Upload tab in the Audio Management screen. The tab will display a paginated list of uploaded audio files and provide functionality to upload new audio files.

## Feature Requirements

### 1. Audio Search Endpoint Integration

#### Endpoint Details
- **URL**: `audio/search`
- **Method**: POST
- **Purpose**: Retrieve paginated list of audio files with filtering capabilities

#### Request Payload
```json
{
  "from_date": "2025-01-01T00:00:00",
  "to_date": "2025-12-31T23:59:59",
  "has_transcript": true,
  "order": "DESC",
  "page": 1,
  "page_size": 10,
  "search": "interview",
  "status": "completed"
}
```

**Payload Fields**:
- `from_date` (optional): ISO 8601 datetime string - filter files created after this date
- `to_date` (optional): ISO 8601 datetime string - filter files created before this date
- `has_transcript` (optional): boolean - filter by transcript availability
- `order` (required): string - "ASC" or "DESC" for sorting order
- `page` (required): number - current page number (starts from 1)
- `page_size` (required): number - number of items per page (default: 10)
- `search` (optional): string - search term for filename/content
- `status` (optional): string - filter by status ("completed", "processing", "failed")

#### Response Structure
```json
{
  "code": 200,
  "success": true,
  "message": "SUCCESSFULLY",
  "data": {
    "data": [
      {
        "id": 0,
        "user_id": 0,
        "filename": "string",
        "original_filename": "string",
        "file_path": "string",
        "file_size": 0,
        "duration": 0,
        "format": "string",
        "status": "string",
        "transcription": "string",
        "confidence_score": 0,
        "created_at": "2025-12-24T15:56:26.297Z",
        "updated_at": "2025-12-24T15:56:26.297Z"
      }
    ],
    "meta": {
      "page": 0,
      "page_size": 0,
      "item_count": 0,
      "page_count": 0,
      "has_previous_page": true,
      "has_next_page": true
    }
  }
}
```

### 2. Pagination Implementation

#### Scroll Pagination Requirements
- **Initial Load**: Load first 10 items on tab initialization
- **Lazy Loading**: Load next page when user scrolls near bottom of list
- **Loading States**: Display loading indicator during data fetch
- **End Detection**: Stop loading when `has_next_page` is false
- **Error Handling**: Display error message if request fails, allow retry

#### Implementation Strategy
1. Use `ScrollController` to detect scroll position
2. Trigger load when scroll reaches 80% of total scroll extent
3. Maintain state for:
   - Current page number
   - Total items loaded
   - Has more pages flag
   - Loading state
   - Error state

#### Example Pagination Logic
```dart
class AudioUploadTabState {
  List<AudioFile> audioFiles = [];
  int currentPage = 1;
  bool isLoading = false;
  bool hasMorePages = true;
  String? errorMessage;
}

void _loadNextPage() async {
  if (isLoading || !hasMorePages) return;
  
  setState(() => isLoading = true);
  
  try {
    final result = await searchAudioFiles(page: currentPage);
    setState(() {
      audioFiles.addAll(result.data);
      currentPage++;
      hasMorePages = result.meta.hasNextPage;
      isLoading = false;
      errorMessage = null;
    });
  } catch (e) {
    setState(() {
      isLoading = false;
      errorMessage = e.toString();
    });
  }
}
```

### 3. Audio Upload Functionality

#### Upload Endpoint Details
- **URL**: `audio/upload-async`
- **Method**: POST
- **Content-Type**: `multipart/form-data`
- **Purpose**: Upload audio file asynchronously

#### Request Structure
```dart
FormData formData = FormData.fromMap({
  'file': await MultipartFile.fromFile(
    audioFile.path,
    filename: audioFile.path.split('/').last,
  ),
});
```

#### Response Structure
Same as current `AudioUploadResultModel`:
```json
{
  "code": 200,
  "success": true,
  "message": "File uploaded successfully",
  "data": {
    "id": 123,
    "filename": "audio_123.mp3",
    "status": "queued"
  }
}
```

#### Upload Flow
1. **File Selection**: User clicks upload button → opens file picker
2. **File Validation**: Validate file type and size
3. **Upload Request**: POST to `audio/upload-async` endpoint
4. **Success Handling**: 
   - Check `success === true`
   - Switch to **Tasks tab** to monitor upload/transcription/summary progress
   - This behavior should match the flow after recording audio completes
5. **Error Handling**: Display error message if upload fails

### 4. Data Layer Implementation

#### Add New Models

##### AudioSearchCriteria Model
```dart
class AudioSearchCriteria {
  final DateTime? fromDate;
  final DateTime? toDate;
  final bool? hasTranscript;
  final String order; // "ASC" or "DESC"
  final int page;
  final int pageSize;
  final String? search;
  final String? status;

  const AudioSearchCriteria({
    this.fromDate,
    this.toDate,
    this.hasTranscript,
    required this.order,
    required this.page,
    required this.pageSize,
    this.search,
    this.status,
  });

  Map<String, dynamic> toJson() {
    return {
      if (fromDate != null) 'from_date': fromDate!.toIso8601String(),
      if (toDate != null) 'to_date': toDate!.toIso8601String(),
      if (hasTranscript != null) 'has_transcript': hasTranscript,
      'order': order,
      'page': page,
      'page_size': pageSize,
      if (search != null && search!.isNotEmpty) 'search': search,
      if (status != null && status!.isNotEmpty) 'status': status,
    };
  }
}
```

##### AudioSearchResult Model
```dart
class AudioSearchResult {
  final List<AudioFile> data;
  final PaginationMeta meta;

  const AudioSearchResult({
    required this.data,
    required this.meta,
  });

  factory AudioSearchResult.fromJson(Map<String, dynamic> json) {
    return AudioSearchResult(
      data: (json['data'] as List)
          .map((item) => AudioFile.fromJson(item))
          .toList(),
      meta: PaginationMeta.fromJson(json['meta']),
    );
  }
}

class PaginationMeta {
  final int page;
  final int pageSize;
  final int itemCount;
  final int pageCount;
  final bool hasPreviousPage;
  final bool hasNextPage;

  const PaginationMeta({
    required this.page,
    required this.pageSize,
    required this.itemCount,
    required this.pageCount,
    required this.hasPreviousPage,
    required this.hasNextPage,
  });

  factory PaginationMeta.fromJson(Map<String, dynamic> json) {
    return PaginationMeta(
      page: json['page'] as int,
      pageSize: json['page_size'] as int,
      itemCount: json['item_count'] as int,
      pageCount: json['page_count'] as int,
      hasPreviousPage: json['has_previous_page'] as bool,
      hasNextPage: json['has_next_page'] as bool,
    );
  }
}
```

##### AudioFile Entity
```dart
class AudioFile {
  final int id;
  final int userId;
  final String filename;
  final String originalFilename;
  final String filePath;
  final int fileSize;
  final double duration;
  final String format;
  final String status;
  final String? transcription;
  final double? confidenceScore;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AudioFile({
    required this.id,
    required this.userId,
    required this.filename,
    required this.originalFilename,
    required this.filePath,
    required this.fileSize,
    required this.duration,
    required this.format,
    required this.status,
    this.transcription,
    this.confidenceScore,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AudioFile.fromJson(Map<String, dynamic> json) {
    return AudioFile(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      filename: json['filename'] as String,
      originalFilename: json['original_filename'] as String,
      filePath: json['file_path'] as String,
      fileSize: json['file_size'] as int,
      duration: (json['duration'] as num).toDouble(),
      format: json['format'] as String,
      status: json['status'] as String,
      transcription: json['transcription'] as String?,
      confidenceScore: json['confidence_score'] != null 
          ? (json['confidence_score'] as num).toDouble() 
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}
```

#### Update Remote Data Source

Add to `AudioManagerRemoteDataSource`:

```dart
abstract class AudioManagerRemoteDataSource {
  // Existing methods...
  Future<AudioSearchResult> searchAudioFiles(AudioSearchCriteria criteria);
}

class AudioManagerRemoteDataSourceImpl implements AudioManagerRemoteDataSource {
  // Existing implementation...

  @override
  Future<AudioSearchResult> searchAudioFiles(AudioSearchCriteria criteria) async {
    try {
      final response = await dio.post(
        AppConstants.audioSearchEndpoint, // Add this constant
        data: criteria.toJson(),
      );

      final data = _extractData(
        response,
        fallbackMessage: 'Failed to search audio files',
      );

      return AudioSearchResult.fromJson(data);
    } on DioException catch (e) {
      throw _handleDioException(
        e,
        fallbackMessage: 'Failed to search audio files',
      );
    }
  }
}
```

#### Update Repository

Add to `AudioManagerRepository`:

```dart
abstract class AudioManagerRepository {
  // Existing methods...
  Future<Either<Failure, AudioSearchResult>> searchAudioFiles(AudioSearchCriteria criteria);
}

class AudioManagerRepositoryImpl implements AudioManagerRepository {
  // Existing implementation...

  @override
  Future<Either<Failure, AudioSearchResult>> searchAudioFiles(
    AudioSearchCriteria criteria,
  ) async {
    try {
      final result = await remoteDataSource.searchAudioFiles(criteria);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }
}
```

#### Create Use Case

```dart
class SearchAudioFiles {
  final AudioManagerRepository repository;

  SearchAudioFiles(this.repository);

  Future<Either<Failure, AudioSearchResult>> call(
    AudioSearchCriteria criteria,
  ) async {
    return await repository.searchAudioFiles(criteria);
  }
}
```

### 5. Update App Constants

Add new endpoint to `AppConstants`:

```dart
class AppConstants {
  // Existing constants...
  static const String audioSearchEndpoint = '/audio/search';
  // Keep existing audioUploadEndpoint or update to audio/upload-async if needed
}
```

### 6. State Management (BLoC)

#### Events

```dart
// Load initial audio files
class LoadAudioFiles extends AudioManagerEvent {
  final AudioSearchCriteria criteria;
  const LoadAudioFiles(this.criteria);
}

// Load next page
class LoadMoreAudioFiles extends AudioManagerEvent {}

// Refresh audio list
class RefreshAudioFiles extends AudioManagerEvent {}

// Upload audio file
class UploadAudioFileFromPicker extends AudioManagerEvent {
  final File audioFile;
  const UploadAudioFileFromPicker(this.audioFile);
}
```

#### States

```dart
class AudioFilesLoadInProgress extends AudioManagerState {}

class AudioFilesLoadSuccess extends AudioManagerState {
  final List<AudioFile> audioFiles;
  final PaginationMeta meta;
  final bool isLoadingMore;

  const AudioFilesLoadSuccess({
    required this.audioFiles,
    required this.meta,
    this.isLoadingMore = false,
  });
}

class AudioFilesLoadFailure extends AudioManagerState {
  final String message;
  const AudioFilesLoadFailure(this.message);
}
```

### 7. UI Implementation

#### Upload Tab Widget Structure

```dart
class AudioUploadTab extends StatefulWidget {
  const AudioUploadTab({Key? key}) : super(key: key);

  @override
  State<AudioUploadTab> createState() => _AudioUploadTabState();
}

class _AudioUploadTabState extends State<AudioUploadTab> {
  final ScrollController _scrollController = ScrollController();
  
  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _scrollController.addListener(_onScroll);
  }

  void _loadInitialData() {
    context.read<AudioManagerBloc>().add(
      LoadAudioFiles(
        AudioSearchCriteria(
          order: 'DESC',
          page: 1,
          pageSize: 10,
        ),
      ),
    );
  }

  void _onScroll() {
    if (_isBottom) {
      context.read<AudioManagerBloc>().add(LoadMoreAudioFiles());
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.8);
  }

  Future<void> _pickAndUploadFile() async {
    // Use file_picker package
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      context.read<AudioManagerBloc>().add(
        UploadAudioFileFromPicker(file),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AudioManagerBloc, AudioManagerState>(
      listener: (context, state) {
        // After successful upload, navigate to Tasks tab
        if (state is AudioUploadSuccess) {
          // Switch to Tasks tab to view progress
          // This should match the behavior after recording completes
          DefaultTabController.of(context)?.animateTo(1); // Tasks tab index
        }
      },
      builder: (context, state) {
        return Scaffold(
          body: _buildBody(state),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _pickAndUploadFile,
            icon: Icon(Icons.upload_file),
            label: Text('Upload Audio'),
          ),
        );
      },
    );
  }

  Widget _buildBody(AudioManagerState state) {
    if (state is AudioFilesLoadSuccess) {
      return RefreshIndicator(
        onRefresh: () async {
          context.read<AudioManagerBloc>().add(RefreshAudioFiles());
        },
        child: ListView.builder(
          controller: _scrollController,
          itemCount: state.audioFiles.length + (state.meta.hasNextPage ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= state.audioFiles.length) {
              return Center(child: CircularProgressIndicator());
            }
            return AudioFileListItem(audioFile: state.audioFiles[index]);
          },
        ),
      );
    }
    
    if (state is AudioFilesLoadFailure) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(state.message),
            ElevatedButton(
              onPressed: _loadInitialData,
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }
    
    return Center(child: CircularProgressIndicator());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
```

#### Audio File List Item

```dart
class AudioFileListItem extends StatelessWidget {
  final AudioFile audioFile;

  const AudioFileListItem({
    Key? key,
    required this.audioFile,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Icon(Icons.audio_file, size: 40),
        title: Text(audioFile.originalFilename),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Duration: ${_formatDuration(audioFile.duration)}'),
            Text('Status: ${audioFile.status}'),
            Text('Created: ${_formatDate(audioFile.createdAt)}'),
          ],
        ),
        trailing: _buildStatusIcon(audioFile.status),
        onTap: () {
          // Navigate to detail view or play audio
        },
      ),
    );
  }

  String _formatDuration(double seconds) {
    final duration = Duration(seconds: seconds.toInt());
    return '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Icon(Icons.check_circle, color: Colors.green);
      case 'processing':
        return Icon(Icons.sync, color: Colors.orange);
      case 'failed':
        return Icon(Icons.error, color: Colors.red);
      default:
        return Icon(Icons.help_outline);
    }
  }
}
```

### 8. Post-Upload Navigation

After successful upload (when `success === true` in response):
1. Automatically switch to **Tasks tab**
2. The Tasks tab should display the newly uploaded file in the appropriate task queue
3. User can monitor upload → transcription → summarization progress
4. This matches the existing behavior after recording audio

Implementation:
```dart
// In BLoC listener
if (state is AudioUploadSuccess) {
  // Get the TabController from the parent widget
  final tabController = DefaultTabController.of(context);
  // Navigate to Tasks tab (assuming it's at index 1)
  tabController?.animateTo(1);
  
  // Optionally show a snackbar
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Upload started. Check Tasks tab for progress.')),
  );
}
```

## Implementation Checklist

- [ ] Add `audioSearchEndpoint` constant to `AppConstants`
- [ ] Create `AudioSearchCriteria` model in domain/entities
- [ ] Create `AudioSearchResult` model in domain/entities  
- [ ] Create `AudioFile` entity in domain/entities
- [ ] Create `PaginationMeta` model in domain/entities
- [ ] Add `searchAudioFiles` method to `AudioManagerRemoteDataSource`
- [ ] Add `searchAudioFiles` method to `AudioManagerRepository`
- [ ] Create `SearchAudioFiles` use case
- [ ] Add new events to `AudioManagerBloc`: `LoadAudioFiles`, `LoadMoreAudioFiles`, `RefreshAudioFiles`
- [ ] Add new states to `AudioManagerBloc`: `AudioFilesLoadSuccess`, `AudioFilesLoadFailure`
- [ ] Implement pagination logic in BLoC
- [ ] Create `AudioUploadTab` widget
- [ ] Create `AudioFileListItem` widget
- [ ] Implement scroll-based pagination with `ScrollController`
- [ ] Implement file picker integration
- [ ] Implement upload flow with navigation to Tasks tab
- [ ] Add loading indicators for initial load and pagination
- [ ] Add error handling and retry functionality
- [ ] Add pull-to-refresh functionality
- [ ] Test pagination behavior
- [ ] Test upload flow and navigation
- [ ] Verify Tasks tab displays new upload correctly

## Testing Considerations

1. **Pagination Testing**:
   - Verify initial load of 10 items
   - Test scroll-triggered loading
   - Test end-of-list detection
   - Test rapid scrolling behavior

2. **Upload Testing**:
   - Test file selection cancellation
   - Test upload with various file sizes
   - Test network error handling
   - Verify navigation to Tasks tab after upload

3. **UI Testing**:
   - Test loading states
   - Test error states and retry
   - Test pull-to-refresh
   - Test list item interactions

## Notes

- Consider adding filters UI for search criteria (date range, status, etc.)
- Consider adding sorting options (by date, name, duration)
- Consider implementing caching for better performance
- The endpoint path should be confirmed with backend team
- File size limits should be validated before upload
- Supported audio formats should be defined
