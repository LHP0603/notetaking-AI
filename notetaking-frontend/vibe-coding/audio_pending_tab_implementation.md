# Audio Pending Tab Implementation Guide

## Overview
This document provides implementation instructions for the Pending tab in the Audio Management screen. The tab displays audios awaiting transcription and summarization, with preview lists and "See All" navigation to detailed views with filtering capabilities.

## Feature Requirements

### 1. Tab Pending Overview

The Pending tab displays two sections:
1. **Untranscribed Audios**: Shows 3 most recent audios without transcripts
2. **Unsummarized Audios**: Shows 3 most recent audios with transcripts but without summaries

Each section has a "See All" button that navigates to a full-screen list with search, date filtering, and scroll pagination.

### 2. API Integration - Audio Search Endpoint

#### Endpoint Details
- **URL**: `audio/search`
- **Method**: POST
- **Purpose**: Retrieve paginated list of audio files with filtering

#### Request Payload Structure
```json
{
  "from_date": "2025-01-01T00:00:00",
  "to_date": "2025-12-31T23:59:59",
  "has_summary": false,
  "has_transcript": true,
  "order": "DESC",
  "page": 1,
  "page_size": 20,
  "search": "interview",
  "status": "completed"
}
```

#### Specific Queries

**Get Untranscribed Audios**:
```json
{
  "has_transcript": false,
  "order": "DESC",
  "page": 1,
  "page_size": 3,
  "status": "completed"
}
```

**Get Unsummarized Audios**:
```json
{
  "has_transcript": true,
  "has_summary": false,
  "order": "DESC",
  "page": 1,
  "page_size": 3,
  "status": "completed"
}
```

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
        "created_at": "2025-12-25T21:36:19.277Z",
        "updated_at": "2025-12-25T21:36:19.277Z",
        "is_summarize": false
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

### 3. Data Models

#### Update AudioFile Entity

Add the `is_summarize` field to the existing `AudioFile` entity:

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
  final bool isSummarize; // NEW FIELD

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
    required this.isSummarize, // NEW FIELD
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
      isSummarize: json['is_summarize'] as bool? ?? false, // NEW FIELD
    );
  }
}
```

#### Update AudioSearchCriteria Model

Add optional fields for summary and transcript filters:

```dart
class AudioSearchCriteria {
  final DateTime? fromDate;
  final DateTime? toDate;
  final bool? hasTranscript; // For filtering by transcript availability
  final bool? hasSummary;    // For filtering by summary availability
  final String order;
  final int page;
  final int pageSize;
  final String? search;
  final String? status;

  const AudioSearchCriteria({
    this.fromDate,
    this.toDate,
    this.hasTranscript,
    this.hasSummary,
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
      if (hasSummary != null) 'has_summary': hasSummary,
      'order': order,
      'page': page,
      'page_size': pageSize,
      if (search != null && search!.isNotEmpty) 'search': search,
      if (status != null && status!.isNotEmpty) 'status': status,
    };
  }
}
```

### 4. State Management (BLoC)

#### Events

```dart
// Load pending audios (both untranscribed and unsummarized)
class LoadPendingAudios extends AudioManagerEvent {}

// Load more items in the "See All" screen
class LoadMorePendingAudios extends AudioManagerEvent {
  final PendingAudioType type; // untranscribed or unsummarized
  const LoadMorePendingAudios(this.type);
}

// Search/Filter pending audios
class SearchPendingAudios extends AudioManagerEvent {
  final PendingAudioType type;
  final String? searchQuery;
  final DateTime? fromDate;
  final DateTime? toDate;
  
  const SearchPendingAudios({
    required this.type,
    this.searchQuery,
    this.fromDate,
    this.toDate,
  });
}

enum PendingAudioType {
  untranscribed,
  unsummarized,
}
```

#### States

```dart
class PendingAudiosLoadSuccess extends AudioManagerState {
  final List<AudioFile> untranscribedAudios; // First 3 items
  final List<AudioFile> unsummarizedAudios;  // First 3 items
  final int untranscribedCount;
  final int unsummarizedCount;

  const PendingAudiosLoadSuccess({
    required this.untranscribedAudios,
    required this.unsummarizedAudios,
    required this.untranscribedCount,
    required this.unsummarizedCount,
  });
}

class PendingAudiosLoadInProgress extends AudioManagerState {}

class PendingAudiosLoadFailure extends AudioManagerState {
  final String message;
  const PendingAudiosLoadFailure(this.message);
}

// For "See All" screen
class PendingAudioDetailLoadSuccess extends AudioManagerState {
  final List<AudioFile> audioFiles;
  final PaginationMeta meta;
  final bool isLoadingMore;
  final PendingAudioType type;

  const PendingAudioDetailLoadSuccess({
    required this.audioFiles,
    required this.meta,
    required this.type,
    this.isLoadingMore = false,
  });
}
```

#### BLoC Implementation

```dart
class AudioManagerBloc extends Bloc<AudioManagerEvent, AudioManagerState> {
  final SearchAudioFiles searchAudioFiles;

  // ... existing code

  Future<void> _onLoadPendingAudios(
    LoadPendingAudios event,
    Emitter<AudioManagerState> emit,
  ) async {
    emit(PendingAudiosLoadInProgress());

    try {
      // Fetch untranscribed audios
      final untranscribedResult = await searchAudioFiles(
        AudioSearchCriteria(
          hasTranscript: false,
          order: 'DESC',
          page: 1,
          pageSize: 3,
          status: 'completed',
        ),
      );

      // Fetch unsummarized audios
      final unsummarizedResult = await searchAudioFiles(
        AudioSearchCriteria(
          hasTranscript: true,
          hasSummary: false,
          order: 'DESC',
          page: 1,
          pageSize: 3,
          status: 'completed',
        ),
      );

      await untranscribedResult.fold(
        (failure) => emit(PendingAudiosLoadFailure(failure.message)),
        (untranscribedData) async {
          await unsummarizedResult.fold(
            (failure) => emit(PendingAudiosLoadFailure(failure.message)),
            (unsummarizedData) {
              emit(PendingAudiosLoadSuccess(
                untranscribedAudios: untranscribedData.data,
                unsummarizedAudios: unsummarizedData.data,
                untranscribedCount: untranscribedData.meta.itemCount,
                unsummarizedCount: unsummarizedData.meta.itemCount,
              ));
            },
          );
        },
      );
    } catch (e) {
      emit(PendingAudiosLoadFailure(e.toString()));
    }
  }
}
```

### 5. UI Implementation

#### Pending Tab Widget

```dart
class AudioPendingTab extends StatefulWidget {
  const AudioPendingTab({Key? key}) : super(key: key);

  @override
  State<AudioPendingTab> createState() => _AudioPendingTabState();
}

class _AudioPendingTabState extends State<AudioPendingTab> {
  @override
  void initState() {
    super.initState();
    _loadPendingAudios();
  }

  void _loadPendingAudios() {
    context.read<AudioManagerBloc>().add(LoadPendingAudios());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AudioManagerBloc, AudioManagerState>(
      builder: (context, state) {
        if (state is PendingAudiosLoadInProgress) {
          return Center(child: CircularProgressIndicator());
        }

        if (state is PendingAudiosLoadFailure) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(state.message),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadPendingAudios,
                  child: Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (state is PendingAudiosLoadSuccess) {
          return RefreshIndicator(
            onRefresh: () async {
              _loadPendingAudios();
            },
            child: SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPendingSection(
                    title: 'Untranscribed Audios',
                    audios: state.untranscribedAudios,
                    totalCount: state.untranscribedCount,
                    type: PendingAudioType.untranscribed,
                  ),
                  SizedBox(height: 24),
                  _buildPendingSection(
                    title: 'Unsummarized Audios',
                    audios: state.unsummarizedAudios,
                    totalCount: state.unsummarizedCount,
                    type: PendingAudioType.unsummarized,
                  ),
                ],
              ),
            ),
          );
        }

        return SizedBox.shrink();
      },
    );
  }

  Widget _buildPendingSection({
    required String title,
    required List<AudioFile> audios,
    required int totalCount,
    required PendingAudioType type,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (totalCount > 3)
              TextButton(
                onPressed: () => _navigateToSeeAll(type, title),
                child: Text('See All ($totalCount)'),
              ),
          ],
        ),
        SizedBox(height: 12),
        if (audios.isEmpty)
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Text(
                'No pending audios',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          ...audios.map((audio) => AudioFileListItem(audioFile: audio)),
      ],
    );
  }

  void _navigateToSeeAll(PendingAudioType type, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PendingAudioDetailScreen(
          type: type,
          title: title,
        ),
      ),
    );
  }
}
```

#### Pending Audio Detail Screen (See All)

```dart
class PendingAudioDetailScreen extends StatefulWidget {
  final PendingAudioType type;
  final String title;

  const PendingAudioDetailScreen({
    Key? key,
    required this.type,
    required this.title,
  }) : super(key: key);

  @override
  State<PendingAudioDetailScreen> createState() =>
      _PendingAudioDetailScreenState();
}

class _PendingAudioDetailScreenState extends State<PendingAudioDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  
  DateTime? _fromDate;
  DateTime? _toDate;
  String? _searchQuery;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _scrollController.addListener(_onScroll);
  }

  void _loadInitialData() {
    context.read<AudioManagerBloc>().add(
          SearchPendingAudios(
            type: widget.type,
            searchQuery: _searchQuery,
            fromDate: _fromDate,
            toDate: _toDate,
          ),
        );
  }

  void _onScroll() {
    if (_isBottom) {
      context.read<AudioManagerBloc>().add(
            LoadMorePendingAudios(widget.type),
          );
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.8);
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _fromDate != null && _toDate != null
          ? DateTimeRange(start: _fromDate!, end: _toDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _fromDate = picked.start;
        _toDate = picked.end;
      });
      _loadInitialData();
    }
  }

  void _clearDateFilter() {
    setState(() {
      _fromDate = null;
      _toDate = null;
    });
    _loadInitialData();
  }

  void _onSearchChanged(String value) {
    // Debounce search
    Future.delayed(Duration(milliseconds: 500), () {
      if (value == _searchController.text) {
        setState(() {
          _searchQuery = value.isEmpty ? null : value;
        });
        _loadInitialData();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildFilterSection(),
          Expanded(
            child: BlocBuilder<AudioManagerBloc, AudioManagerState>(
              builder: (context, state) {
                if (state is PendingAudioDetailLoadSuccess &&
                    state.type == widget.type) {
                  return _buildAudioList(state);
                }

                if (state is PendingAudiosLoadInProgress) {
                  return Center(child: CircularProgressIndicator());
                }

                if (state is PendingAudiosLoadFailure) {
                  return _buildErrorWidget(state.message);
                }

                return SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search Input
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search audios...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: _onSearchChanged,
          ),
          SizedBox(height: 12),
          // Date Filter
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _selectDateRange,
                  icon: Icon(Icons.date_range),
                  label: Text(
                    _fromDate != null && _toDate != null
                        ? '${_formatDate(_fromDate!)} - ${_formatDate(_toDate!)}'
                        : 'Select Date Range',
                  ),
                ),
              ),
              if (_fromDate != null && _toDate != null) ...[
                SizedBox(width: 8),
                IconButton(
                  onPressed: _clearDateFilter,
                  icon: Icon(Icons.clear),
                  tooltip: 'Clear date filter',
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAudioList(PendingAudioDetailLoadSuccess state) {
    if (state.audioFiles.isEmpty) {
      return Center(
        child: Text(
          'No audios found',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        _loadInitialData();
      },
      child: ListView.builder(
        controller: _scrollController,
        padding: EdgeInsets.all(16),
        itemCount: state.audioFiles.length + 
            (state.meta.hasNextPage ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= state.audioFiles.length) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }
          return AudioFileListItem(
            audioFile: state.audioFiles[index],
          );
        },
      ),
    );
  }

  Widget _buildErrorWidget(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red),
          SizedBox(height: 16),
          Text(message),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadInitialData,
            child: Text('Retry'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}
```

### 6. BLoC Handler for Detail Screen

```dart
Future<void> _onSearchPendingAudios(
  SearchPendingAudios event,
  Emitter<AudioManagerState> emit,
) async {
  emit(PendingAudiosLoadInProgress());

  try {
    final criteria = AudioSearchCriteria(
      hasTranscript: event.type == PendingAudioType.untranscribed ? false : true,
      hasSummary: event.type == PendingAudioType.unsummarized ? false : null,
      order: 'DESC',
      page: 1,
      pageSize: 10,
      status: 'completed',
      search: event.searchQuery,
      fromDate: event.fromDate,
      toDate: event.toDate,
    );

    final result = await searchAudioFiles(criteria);

    result.fold(
      (failure) => emit(PendingAudiosLoadFailure(failure.message)),
      (data) => emit(PendingAudioDetailLoadSuccess(
        audioFiles: data.data,
        meta: data.meta,
        type: event.type,
      )),
    );
  } catch (e) {
    emit(PendingAudiosLoadFailure(e.toString()));
  }
}

Future<void> _onLoadMorePendingAudios(
  LoadMorePendingAudios event,
  Emitter<AudioManagerState> emit,
) async {
  final currentState = state;
  if (currentState is! PendingAudioDetailLoadSuccess) return;
  if (currentState.isLoadingMore || !currentState.meta.hasNextPage) return;

  emit(currentState.copyWith(isLoadingMore: true));

  try {
    final criteria = AudioSearchCriteria(
      hasTranscript: event.type == PendingAudioType.untranscribed ? false : true,
      hasSummary: event.type == PendingAudioType.unsummarized ? false : null,
      order: 'DESC',
      page: currentState.meta.page + 1,
      pageSize: 10,
      status: 'completed',
    );

    final result = await searchAudioFiles(criteria);

    result.fold(
      (failure) => emit(PendingAudiosLoadFailure(failure.message)),
      (data) => emit(PendingAudioDetailLoadSuccess(
        audioFiles: [...currentState.audioFiles, ...data.data],
        meta: data.meta,
        type: event.type,
        isLoadingMore: false,
      )),
    );
  } catch (e) {
    emit(currentState.copyWith(isLoadingMore: false));
  }
}
```

### 7. Reuse AudioFileListItem Component

The `AudioFileListItem` widget should be reused from the Upload tab implementation. Ensure it handles:
- Display of audio metadata (filename, duration, status, created date)
- Status icons (completed, processing, failed)
- Tap interaction for playing or viewing details
- Same styling and layout as Upload tab

```dart
// Reuse from Upload tab
class AudioFileListItem extends StatelessWidget {
  final AudioFile audioFile;

  const AudioFileListItem({
    Key? key,
    required this.audioFile,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(Icons.audio_file, size: 40),
        title: Text(audioFile.originalFilename),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Duration: ${_formatDuration(audioFile.duration)}'),
            Text('Status: ${audioFile.status}'),
            Text('Created: ${_formatDate(audioFile.createdAt)}'),
            if (!audioFile.isSummarize && audioFile.transcription != null)
              Text(
                'Not summarized',
                style: TextStyle(color: Colors.orange),
              ),
          ],
        ),
        trailing: _buildStatusIcon(audioFile),
        onTap: () {
          // Handle audio item tap (play, view details, etc.)
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

  Widget _buildStatusIcon(AudioFile audioFile) {
    // Show different icons based on pending status
    if (audioFile.transcription == null) {
      return Icon(Icons.transcribe, color: Colors.orange);
    } else if (!audioFile.isSummarize) {
      return Icon(Icons.summarize, color: Colors.blue);
    } else {
      return Icon(Icons.check_circle, color: Colors.green);
    }
  }
}
```

## Implementation Checklist

### Data Layer
- [ ] Add `is_summarize` field to `AudioFile` entity
- [ ] Add `hasTranscript` and `hasSummary` fields to `AudioSearchCriteria`
- [ ] Ensure `searchAudioFiles` method in repository supports new criteria

### BLoC Layer
- [ ] Add `LoadPendingAudios` event
- [ ] Add `LoadMorePendingAudios` event
- [ ] Add `SearchPendingAudios` event
- [ ] Add `PendingAudioType` enum (untranscribed, unsummarized)
- [ ] Add `PendingAudiosLoadSuccess` state
- [ ] Add `PendingAudiosLoadInProgress` state
- [ ] Add `PendingAudiosLoadFailure` state
- [ ] Add `PendingAudioDetailLoadSuccess` state
- [ ] Implement `_onLoadPendingAudios` handler
- [ ] Implement `_onSearchPendingAudios` handler
- [ ] Implement `_onLoadMorePendingAudios` handler

### UI Layer
- [ ] Create `AudioPendingTab` widget
- [ ] Implement two-section layout (Untranscribed + Unsummarized)
- [ ] Show only 3 items per section
- [ ] Add "See All" button with count
- [ ] Implement pull-to-refresh
- [ ] Create `PendingAudioDetailScreen` widget
- [ ] Add AppBar with title
- [ ] Implement search input with debounce
- [ ] Implement date range picker
- [ ] Add clear date filter button
- [ ] Implement scroll pagination
- [ ] Add loading indicators (initial + pagination)
- [ ] Add error handling and retry
- [ ] Reuse `AudioFileListItem` component from Upload tab
- [ ] Ensure consistent UI/UX with Upload tab

### Testing
- [ ] Test loading pending audios (both types)
- [ ] Test "See All" navigation
- [ ] Test search functionality
- [ ] Test date filtering
- [ ] Test combined search + date filter
- [ ] Test scroll pagination
- [ ] Test pull-to-refresh
- [ ] Test error states and retry
- [ ] Test empty states
- [ ] Verify UI consistency with Upload tab

## Edge Cases and Considerations

### Empty States
- Handle when no untranscribed audios exist
- Handle when no unsummarized audios exist
- Handle when search/filter returns no results

### Loading States
- Show loading indicator during initial load
- Show shimmer or skeleton loading for better UX
- Show bottom loading indicator during pagination
- Prevent multiple simultaneous requests

### Error Handling
- Network errors during initial load
- Network errors during pagination
- Invalid date range selection
- API response errors

### Performance
- Debounce search input (500ms recommended)
- Implement efficient list rendering
- Consider caching recent searches
- Optimize image/audio preview loading

### UX Improvements
- Add visual feedback for active filters
- Show total count in section headers
- Add ability to clear individual filters
- Consider adding sort options (by date, name, duration)
- Add audio preview on long press
- Implement swipe actions (delete, retry)

## Notes

- The `AudioFileListItem` component must be shared between Upload and Pending tabs to maintain consistency
- Consider implementing a badge or indicator on tab icon showing pending count
- Date range picker should default to reasonable ranges (e.g., last 30 days)
- Search should be case-insensitive server-side
- Consider adding filter chips showing active filters
- May want to add analytics to track which filters are most used
