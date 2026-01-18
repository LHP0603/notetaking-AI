# Audio Manager Feature Implementation Guide

## Overview

This document provides comprehensive instructions for implementing an Audio Manager feature with a tabbed interface for managing audio files, monitoring server tasks, and tracking processing status. The feature follows Clean Architecture principles consistent with the existing Voicely project structure.

## Table of Contents

1. [Feature Overview](#feature-overview)
2. [UI Structure & Components](#ui-structure--components)
3. [Architecture Design](#architecture-design)
4. [API Endpoints](#api-endpoints)
5. [Implementation Steps](#implementation-steps)
6. [Detailed Component Specifications](#detailed-component-specifications)
7. [State Management](#state-management)
8. [Navigation & Integration](#navigation--integration)
9. [Audio Playback](#audio-playback)
10. [Common Widgets](#common-widgets)

---

## Feature Overview

Create a new feature module `audio_manager` (similar to `auth`, `profile`, `recording`, etc.) that provides a comprehensive interface for:

- **Uploading audio files** and viewing uploaded files
- **Monitoring server tasks** (uploading, transcribing, summarizing)
- **Tracking pending tasks** (untranscribed audios, unsummarized transcripts)

### Key Characteristics

- Tab-based navigation using `TabBar` and `TabBarView`
- Reusable common widgets for consistency
- Real-time task monitoring with loading animations
- Audio playback functionality using `audioplayers` package
- Search and filter capabilities
- Clean Architecture with BLoC state management

---

## UI Structure & Components

### Main Screen Layout

```
┌─────────────────────────────────────────┐
│  Audio Manager                  [Filter]│
│  ┌──────┬──────────┬────────────┐      │
│  │Upload│  Tasks   │  Pending   │      │
│  └──────┴──────────┴────────────┘      │
├─────────────────────────────────────────┤
│                                         │
│  [Tab Content Area]                     │
│                                         │
│                                         │
│                                         │
│                                         │
│                                         │
│                                         │
├─────────────────────────────────────────┤
│         [Upload Button - Fixed]         │
└─────────────────────────────────────────┘
```

### Tab 1: Upload Audio Files

**Layout:**
```
┌─────────────────────────────────────────┐
│  [Search Input]          [Filter Icon]  │
├─────────────────────────────────────────┤
│                                         │
│  [Audio Item Widget]                    │
│  ┌──────┬────────────────────┬────┐    │
│  │ Icon │ Title              │ >  │    │
│  │      │ Description        │    │    │
│  └──────┴────────────────────────┴────┘│
│                                         │
│  [Audio Item Widget]                    │
│  [Audio Item Widget]                    │
│  ...                                    │
│                                         │
├─────────────────────────────────────────┤
│    [Upload Audio File Button - Fixed]   │
└─────────────────────────────────────────┘
```

**Features:**
- Search bar at top for filtering by filename
- Filter button for date range filtering (from_date, to_date)
- List of uploaded audio files (scrollable)
- Each item shows: large audio icon (left), title (filename), description (upload date/size)
- Click on item → Show audio player popup
- Fixed upload button at bottom

### Tab 2: Server Tasks

**Layout:**
```
┌─────────────────────────────────────────┐
│  ▼ Uploading (3)                        │
│  ┌──────────────────────────────────┐   │
│  │  [Loading Animation + Audio Icon]│   │
│  │  File 1.mp3                      │   │
│  │  Processing...                   │   │
│  └──────────────────────────────────┘   │
│  [Task Widget]                          │
│  [Task Widget]                          │
│                                         │
│  ▼ Transcribing (2)                     │
│  [Task Widget with Document Icon]       │
│  [Task Widget]                          │
│                                         │
│  ▼ Summarizing (1)                      │
│  [Task Widget with Script Icon]         │
│                                         │
└─────────────────────────────────────────┘
```

**Features:**
- Three collapsible sections: "Uploading", "Transcribing", "Summarizing"
- Each section has a title with count (e.g., "Uploading (3)")
- Sections can be collapsed/expanded
- Task widgets with loading animation overlay on icon (left)
- Click on task → Show notification "Processing [task type]..."
- Different icons for each task type:
  - Uploading: Audio/upload icon
  - Transcribing: Document/text icon
  - Summarizing: Script/summary icon

### Tab 3: Pending Tasks

**Layout:**
```
┌─────────────────────────────────────────┐
│  Audio Not Transcribed         [See All]│
│  ┌──────┬────────────────────┬────┐    │
│  │ Icon │ Audio 1.mp3        │ >  │    │
│  │      │ Uploaded 2 hrs ago │    │    │
│  └──────┴────────────────────────┴────┘│
│  [Task Widget]                          │
│  [Task Widget]                          │
│                                         │
│  Transcript Not Summarized     [See All]│
│  [Task Widget]                          │
│  [Task Widget]                          │
│  [Task Widget]                          │
│                                         │
└─────────────────────────────────────────┘
```

**Features:**
- Two sections in column layout
- Section 1: "Audio Not Transcribed" with "See All" button (if > 3 items)
- Section 2: "Transcript Not Summarized" with "See All" button (if > 3 items)
- Each section displays max 3 items
- Task widgets: icon (left), title, description (below title)
- Click on item → Navigate to appropriate action screen

---

## Architecture Design

### Feature Structure

```
lib/features/audio_manager/
├── data/
│   ├── datasources/
│   │   ├── audio_manager_local_data_source.dart
│   │   └── audio_manager_remote_data_source.dart
│   ├── models/
│   │   ├── audio_file_model.dart
│   │   ├── task_model.dart
│   │   ├── pending_task_model.dart
│   │   └── audio_filter_model.dart
│   └── repositories/
│       └── audio_manager_repository_impl.dart
├── domain/
│   ├── entities/
│   │   ├── audio_file.dart
│   │   ├── server_task.dart
│   │   ├── pending_task.dart
│   │   └── audio_filter.dart
│   ├── repositories/
│   │   └── audio_manager_repository.dart
│   └── usecases/
│       ├── get_uploaded_audios.dart
│       ├── upload_audio_file.dart
│       ├── get_server_tasks.dart
│       ├── get_pending_tasks.dart
│       ├── search_audios.dart
│       └── filter_audios.dart
└── presentation/
    ├── bloc/
    │   ├── audio_manager_bloc.dart
    │   ├── audio_manager_event.dart
    │   └── audio_manager_state.dart
    ├── pages/
    │   ├── audio_manager_page.dart
    │   ├── tabs/
    │   │   ├── upload_tab.dart
    │   │   ├── tasks_tab.dart
    │   │   └── pending_tab.dart
    │   └── widgets/
    │       ├── audio_player_dialog.dart
    │       └── filter_dialog.dart
    └── widgets/
        ├── common_task_item.dart
        ├── collapsible_section.dart
        ├── loading_task_item.dart
        └── search_filter_bar.dart
```

---

## API Endpoints

### 1. Get Audio Files

**Endpoint:** `GET /audio/files`

**Query Parameters:**
- `search` (optional): Search by filename
- `from_date` (optional): Filter from date (ISO 8601)
- `to_date` (optional): Filter to date (ISO 8601)
- `page` (optional): Page number (default: 1)
- `limit` (optional): Items per page (default: 20)

**Response:**
```json
{
  "code": 200,
  "success": true,
  "message": "AUDIO_FILES_RETRIEVED",
  "data": {
    "items": [
      {
        "id": 1,
        "filename": "meeting_2025.mp3",
        "file_path": "uploads/audio/1_abc123.mp3",
        "file_size": 5242880,
        "duration": 180.5,
        "upload_date": "2025-12-24T10:30:00Z",
        "status": "completed"
      }
    ],
    "total": 25,
    "page": 1,
    "limit": 20
  }
}
```

### 2. Get Audio File Details

**Endpoint:** `GET /audio/files/{audio_id}`

**Response:**
```json
{
  "code": 200,
  "success": true,
  "message": "AUDIO_FILE_RETRIEVED",
  "data": {
    "id": 1,
    "filename": "meeting_2025.mp3",
    "file_path": "uploads/audio/1_abc123.mp3",
    "file_size": 5242880,
    "duration": 180.5,
    "upload_date": "2025-12-24T10:30:00Z",
    "status": "completed",
    "transcription_id": 123,
    "has_summary": true
  }
}
```

**Audio URL Construction:**
```dart
final audioUrl = '${AppConstants.baseUrl}/${audioFile.filePath}';
// Example: http://10.0.2.2:8000/uploads/audio/3_a31f4371cd474948af3437f1d05d4eab.mp3
```

### 3. Get Server Tasks

**Endpoint:** `GET /tasks/active`

**Response:**
```json
{
  "code": 200,
  "success": true,
  "message": "ACTIVE_TASKS_RETRIEVED",
  "data": {
    "uploading": [
      {
        "task_id": "upload_001",
        "filename": "audio1.mp3",
        "progress": 45,
        "status": "uploading",
        "started_at": "2025-12-24T10:30:00Z"
      }
    ],
    "transcribing": [
      {
        "task_id": "transcribe_001",
        "audio_id": 5,
        "filename": "audio2.mp3",
        "status": "transcribing",
        "started_at": "2025-12-24T10:25:00Z"
      }
    ],
    "summarizing": [
      {
        "task_id": "summary_001",
        "transcription_id": 10,
        "filename": "meeting_notes.txt",
        "status": "summarizing",
        "started_at": "2025-12-24T10:20:00Z"
      }
    ]
  }
}
```

### 4. Get Pending Tasks

**Endpoint:** `GET /tasks/pending`

**Response:**
```json
{
  "code": 200,
  "success": true,
  "message": "PENDING_TASKS_RETRIEVED",
  "data": {
    "untranscribed_audios": [
      {
        "audio_id": 15,
        "filename": "new_recording.mp3",
        "upload_date": "2025-12-24T09:00:00Z",
        "file_size": 3145728
      }
    ],
    "unsummarized_transcripts": [
      {
        "transcription_id": 20,
        "audio_filename": "meeting.mp3",
        "transcription_date": "2025-12-24T08:00:00Z",
        "word_count": 1500
      }
    ]
  }
}
```

### 5. Upload Audio File

**Endpoint:** `POST /audio/upload`

**Request:** Multipart form data
- `file`: Audio file (binary)
- `metadata` (optional): JSON with additional info

**Response:**
```json
{
  "code": 200,
  "success": true,
  "message": "AUDIO_UPLOADED_SUCCESS",
  "data": {
    "audio_id": 25,
    "filename": "uploaded_audio.mp3",
    "file_path": "uploads/audio/25_xyz789.mp3",
    "task_id": "upload_025"
  }
}
```

---

## Implementation Steps

### Phase 1: Domain Layer Setup

1. **Create Entities**
   - `AudioFile` - Represents an uploaded audio file
   - `ServerTask` - Represents active server processing task
   - `PendingTask` - Represents pending action items
   - `AudioFilter` - Filter criteria for search/filtering

2. **Define Repository Interface**
   - Methods for fetching audios, tasks, and pending items
   - Upload functionality
   - Search and filter operations

3. **Implement Use Cases**
   - `GetUploadedAudios`
   - `UploadAudioFile`
   - `GetServerTasks`
   - `GetPendingTasks`
   - `SearchAudios`
   - `FilterAudios`

### Phase 2: Data Layer Implementation

1. **Create Models**
   - Extend entities with JSON serialization
   - Add `fromJson` and `toJson` methods

2. **Implement Data Sources**
   - `AudioManagerRemoteDataSource` - API calls
   - `AudioManagerLocalDataSource` - Caching (optional)

3. **Implement Repository**
   - Network connectivity check
   - Error handling
   - Data transformation

### Phase 3: Presentation Layer

1. **Create BLoC**
   - Define events (LoadAudios, UploadAudio, LoadTasks, etc.)
   - Define states (Loading, Loaded, Error, etc.)
   - Implement event handlers

2. **Build Common Widgets**
   - `CommonTaskItem` - Reusable item widget
   - `CollapsibleSection` - For tasks tab
   - `LoadingTaskItem` - With animation overlay
   - `SearchFilterBar` - Search + filter controls

3. **Build Tab Pages**
   - `UploadTab` - File list and upload button
   - `TasksTab` - Active server tasks
   - `PendingTab` - Pending actions

4. **Build Main Page**
   - TabBar controller
   - Tab navigation
   - Overall layout structure

5. **Build Dialogs**
   - `AudioPlayerDialog` - Play audio files
   - `FilterDialog` - Date range filtering

### Phase 4: Integration

1. **Dependency Injection**
   - Register in `injection_container.dart`
   - Setup dependency graph

2. **Navigation**
   - Add routes to `app_router.dart`
   - Update bottom navigation (replace placeholder)

3. **Import Functionality**
   - Reuse `_onImportPressed` logic from `recording_page.dart`
   - Handle file picking and upload

---

## Detailed Component Specifications

### 1. Common Task Item Widget

**File:** `lib/features/audio_manager/presentation/widgets/common_task_item.dart`

**Purpose:** Reusable widget for displaying audio/task items across all tabs

**Design:**
```dart
class CommonTaskItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final VoidCallback onTap;
  final bool showChevron;
  final Widget? trailing;
  final bool isLoading;

  const CommonTaskItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.onTap,
    this.showChevron = true,
    this.trailing,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        margin: EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Color(0xFF282E39),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Icon with optional loading overlay
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 28),
                ),
                if (isLoading)
                  SizedBox(
                    width: 56,
                    height: 56,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(iconColor),
                    ),
                  ),
              ],
            ),
            SizedBox(width: 16),
            // Title and description
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Trailing (chevron or custom widget)
            if (trailing != null)
              trailing!
            else if (showChevron)
              Icon(Icons.chevron_right, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }
}
```

**Usage Examples:**

```dart
// Upload tab - Audio item
CommonTaskItem(
  icon: Icons.audiotrack,
  iconColor: Colors.blue,
  title: 'Meeting Recording.mp3',
  description: 'Uploaded 2 hours ago • 5.2 MB',
  onTap: () => _showAudioPlayer(context, audioFile),
)

// Tasks tab - Uploading task
CommonTaskItem(
  icon: Icons.upload_file,
  iconColor: Colors.orange,
  title: 'Audio Upload.mp3',
  description: 'Uploading...',
  isLoading: true,
  showChevron: false,
  onTap: () => _showTaskNotification(context, 'Uploading'),
)

// Pending tab - Untranscribed audio
CommonTaskItem(
  icon: Icons.mic,
  iconColor: Colors.purple,
  title: 'New Recording.mp3',
  description: 'Ready to transcribe',
  onTap: () => _navigateToTranscription(audioId),
)
```

### 2. Collapsible Section Widget

**File:** `lib/features/audio_manager/presentation/widgets/collapsible_section.dart`

**Purpose:** Expandable/collapsible section for tasks tab

**Design:**
```dart
class CollapsibleSection extends StatefulWidget {
  final String title;
  final int count;
  final List<Widget> children;
  final bool initiallyExpanded;

  const CollapsibleSection({
    required this.title,
    required this.count,
    required this.children,
    this.initiallyExpanded = true,
  });

  @override
  State<CollapsibleSection> createState() => _CollapsibleSectionState();
}

class _CollapsibleSectionState extends State<CollapsibleSection> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              children: [
                Icon(
                  _isExpanded ? Icons.keyboard_arrow_down : Icons.chevron_right,
                  color: Colors.white,
                ),
                SizedBox(width: 8),
                Text(
                  '${widget.title} (${widget.count})',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_isExpanded)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Column(children: widget.children),
          ),
        SizedBox(height: 8),
      ],
    );
  }
}
```

### 3. Search and Filter Bar

**File:** `lib/features/audio_manager/presentation/widgets/search_filter_bar.dart`

**Design:**
```dart
class SearchFilterBar extends StatelessWidget {
  final TextEditingController searchController;
  final VoidCallback onFilterPressed;
  final ValueChanged<String> onSearchChanged;
  final bool hasActiveFilters;

  const SearchFilterBar({
    required this.searchController,
    required this.onFilterPressed,
    required this.onSearchChanged,
    this.hasActiveFilters = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: searchController,
              onChanged: onSearchChanged,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search audio files...',
                hintStyle: TextStyle(color: Colors.grey[500]),
                prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                filled: true,
                fillColor: Color(0xFF282E39),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
          SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              color: hasActiveFilters ? Colors.blue : Color(0xFF282E39),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(
                Icons.filter_list,
                color: hasActiveFilters ? Colors.white : Colors.grey[500],
              ),
              onPressed: onFilterPressed,
            ),
          ),
        ],
      ),
    );
  }
}
```

### 4. Audio Player Dialog

**File:** `lib/features/audio_manager/presentation/pages/widgets/audio_player_dialog.dart`

**Purpose:** Modal dialog for playing audio files

**Dependencies:**
```yaml
dependencies:
  audioplayers: ^5.2.1
```

**Design:**
```dart
import 'package:audioplayers/audioplayers.dart';

class AudioPlayerDialog extends StatefulWidget {
  final String audioUrl;
  final String title;

  const AudioPlayerDialog({
    required this.audioUrl,
    required this.title,
  });

  @override
  State<AudioPlayerDialog> createState() => _AudioPlayerDialogState();
}

class _AudioPlayerDialogState extends State<AudioPlayerDialog> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _initPlayer();
  }

  void _initPlayer() async {
    _audioPlayer.onPlayerStateChanged.listen((state) {
      setState(() {
        _isPlaying = state == PlayerState.playing;
      });
    });

    _audioPlayer.onDurationChanged.listen((duration) {
      setState(() {
        _duration = duration;
      });
    });

    _audioPlayer.onPositionChanged.listen((position) {
      setState(() {
        _position = position;
      });
    });

    // Set audio source
    await _audioPlayer.setSourceUrl(widget.audioUrl);
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _playPause() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.resume();
    }
  }

  void _seekTo(Duration position) {
    _audioPlayer.seek(position);
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Color(0xFF282E39),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Text(
              widget.title,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32),
            
            // Audio icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.audiotrack,
                size: 60,
                color: Colors.blue,
              ),
            ),
            SizedBox(height: 32),
            
            // Progress slider
            Slider(
              value: _position.inSeconds.toDouble(),
              min: 0,
              max: _duration.inSeconds.toDouble(),
              onChanged: (value) => _seekTo(Duration(seconds: value.toInt())),
              activeColor: Colors.blue,
              inactiveColor: Colors.grey[700],
            ),
            
            // Time labels
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDuration(_position),
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                  Text(
                    _formatDuration(_duration),
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
            
            // Play/Pause button
            GestureDetector(
              onTap: _playPause,
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
            SizedBox(height: 24),
            
            // Close button
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Close',
                style: TextStyle(color: Colors.grey[400]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

**Usage:**
```dart
void _showAudioPlayer(BuildContext context, AudioFile audioFile) {
  final audioUrl = '${AppConstants.baseUrl}/${audioFile.filePath}';
  
  showDialog(
    context: context,
    builder: (context) => AudioPlayerDialog(
      audioUrl: audioUrl,
      title: audioFile.filename,
    ),
  );
}
```

### 5. Filter Dialog

**File:** `lib/features/audio_manager/presentation/pages/widgets/filter_dialog.dart`

**Design:**
```dart
class FilterDialog extends StatefulWidget {
  final DateTime? initialFromDate;
  final DateTime? initialToDate;
  final Function(DateTime?, DateTime?) onApply;

  const FilterDialog({
    this.initialFromDate,
    this.initialToDate,
    required this.onApply,
  });

  @override
  State<FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<FilterDialog> {
  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  void initState() {
    super.initState();
    _fromDate = widget.initialFromDate;
    _toDate = widget.initialToDate;
  }

  Future<void> _selectFromDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _fromDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() => _fromDate = date);
    }
  }

  Future<void> _selectToDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _toDate ?? DateTime.now(),
      firstDate: _fromDate ?? DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() => _toDate = date);
    }
  }

  void _clearFilters() {
    setState(() {
      _fromDate = null;
      _toDate = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Color(0xFF282E39),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filter Audio Files',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: Colors.grey[400]),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            SizedBox(height: 24),
            
            // From Date
            Text(
              'From Date',
              style: TextStyle(color: Colors.grey[400], fontSize: 14),
            ),
            SizedBox(height: 8),
            InkWell(
              onTap: _selectFromDate,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Color(0xFF1A1F2C),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _fromDate != null
                          ? '${_fromDate!.day}/${_fromDate!.month}/${_fromDate!.year}'
                          : 'Select date',
                      style: TextStyle(
                        color: _fromDate != null ? Colors.white : Colors.grey[500],
                      ),
                    ),
                    Icon(Icons.calendar_today, color: Colors.grey[500], size: 20),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            
            // To Date
            Text(
              'To Date',
              style: TextStyle(color: Colors.grey[400], fontSize: 14),
            ),
            SizedBox(height: 8),
            InkWell(
              onTap: _selectToDate,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Color(0xFF1A1F2C),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _toDate != null
                          ? '${_toDate!.day}/${_toDate!.month}/${_toDate!.year}'
                          : 'Select date',
                      style: TextStyle(
                        color: _toDate != null ? Colors.white : Colors.grey[500],
                      ),
                    ),
                    Icon(Icons.calendar_today, color: Colors.grey[500], size: 20),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _clearFilters,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey[400],
                      side: BorderSide(color: Colors.grey[700]!),
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text('Clear'),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onApply(_fromDate, _toDate);
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text('Apply'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## State Management

### BLoC Events

```dart
// lib/features/audio_manager/presentation/bloc/audio_manager_event.dart

abstract class AudioManagerEvent extends Equatable {
  const AudioManagerEvent();

  @override
  List<Object?> get props => [];
}

class LoadUploadedAudios extends AudioManagerEvent {
  final String? searchQuery;
  final DateTime? fromDate;
  final DateTime? toDate;

  const LoadUploadedAudios({
    this.searchQuery,
    this.fromDate,
    this.toDate,
  });

  @override
  List<Object?> get props => [searchQuery, fromDate, toDate];
}

class UploadAudioFile extends AudioManagerEvent {
  final File audioFile;

  const UploadAudioFile(this.audioFile);

  @override
  List<Object?> get props => [audioFile];
}

class LoadServerTasks extends AudioManagerEvent {
  const LoadServerTasks();
}

class LoadPendingTasks extends AudioManagerEvent {
  const LoadPendingTasks();
}

class SearchAudios extends AudioManagerEvent {
  final String query;

  const SearchAudios(this.query);

  @override
  List<Object?> get props => [query];
}

class ApplyFilter extends AudioManagerEvent {
  final DateTime? fromDate;
  final DateTime? toDate;

  const ApplyFilter({this.fromDate, this.toDate});

  @override
  List<Object?> get props => [fromDate, toDate];
}

class RefreshAllData extends AudioManagerEvent {
  const RefreshAllData();
}
```

### BLoC States

```dart
// lib/features/audio_manager/presentation/bloc/audio_manager_state.dart

abstract class AudioManagerState extends Equatable {
  const AudioManagerState();

  @override
  List<Object?> get props => [];
}

class AudioManagerInitial extends AudioManagerState {}

class AudioManagerLoading extends AudioManagerState {}

class AudiosLoaded extends AudioManagerState {
  final List<AudioFile> audios;
  final int totalCount;

  const AudiosLoaded({
    required this.audios,
    required this.totalCount,
  });

  @override
  List<Object?> get props => [audios, totalCount];
}

class ServerTasksLoaded extends AudioManagerState {
  final List<ServerTask> uploadingTasks;
  final List<ServerTask> transcribingTasks;
  final List<ServerTask> summarizingTasks;

  const ServerTasksLoaded({
    required this.uploadingTasks,
    required this.transcribingTasks,
    required this.summarizingTasks,
  });

  @override
  List<Object?> get props => [uploadingTasks, transcribingTasks, summarizingTasks];
}

class PendingTasksLoaded extends AudioManagerState {
  final List<PendingTask> untranscribedAudios;
  final List<PendingTask> unsummarizedTranscripts;

  const PendingTasksLoaded({
    required this.untranscribedAudios,
    required this.unsummarizedTranscripts,
  });

  @override
  List<Object?> get props => [untranscribedAudios, unsummarizedTranscripts];
}

class AudioUploadProgress extends AudioManagerState {
  final double progress;

  const AudioUploadProgress(this.progress);

  @override
  List<Object?> get props => [progress];
}

class AudioUploadSuccess extends AudioManagerState {
  final String message;

  const AudioUploadSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class AudioManagerError extends AudioManagerState {
  final String message;

  const AudioManagerError(this.message);

  @override
  List<Object?> get props => [message];
}
```

---

## Navigation & Integration

### 1. Update App Router

**File:** `lib/core/routes/app_router.dart`

```dart
class AppRoutes {
  // Existing routes...
  static const String audioManager = '/audio-manager';
}

// In router configuration:
GoRoute(
  path: AppRoutes.audioManager,
  builder: (context, state) => BlocProvider(
    create: (context) => sl<AudioManagerBloc>()
      ..add(const LoadUploadedAudios())
      ..add(const LoadServerTasks())
      ..add(const LoadPendingTasks()),
    child: const AudioManagerPage(),
  ),
),
```

### 2. Update Bottom Navigation

**File:** `lib/features/recording/presentation/pages/recording_page.dart`

Replace the placeholder for "Uploading Screen" with navigation to Audio Manager:

```dart
void _onBottomNavTapped(int index, RecordingState state) {
  if (index == 3) {
    // Navigate to Audio Manager instead of placeholder
    context.push(AppRoutes.audioManager);
    return;
  }
  
  // Existing navigation logic...
}
```

### 3. Reuse Import Functionality

The upload button in the Audio Manager should reuse the existing `_onImportPressed` logic:

```dart
// In UploadTab widget
void _onUploadPressed(BuildContext context) {
  // Use the existing import audio logic from RecordingBloc
  final recordingBloc = sl<RecordingBloc>();
  recordingBloc.add(const ImportAudioRequested());
  
  // Listen for result
  recordingBloc.stream.listen((state) {
    if (state is AudioImported) {
      // Upload the imported file
      context.read<AudioManagerBloc>().add(
        UploadAudioFile(state.audioFile),
      );
    }
  });
}
```

---

## Audio Playback

### Audio URL Construction

```dart
String constructAudioUrl(String filePath) {
  return '${AppConstants.baseUrl}/$filePath';
}

// Example usage:
// File path from API: "uploads/audio/3_a31f4371cd474948af3437f1d05d4eab.mp3"
// Full URL: "http://10.0.2.2:8000/uploads/audio/3_a31f4371cd474948af3437f1d05d4eab.mp3"
```

### Handling Audio Playback

```dart
void _playAudio(BuildContext context, AudioFile audioFile) async {
  final audioUrl = constructAudioUrl(audioFile.filePath);
  
  showDialog(
    context: context,
    builder: (context) => AudioPlayerDialog(
      audioUrl: audioUrl,
      title: audioFile.filename,
    ),
  );
}
```

---

## Common Widgets

### Summary of Reusable Components

1. **CommonTaskItem**
   - Used in: All three tabs
   - Props: icon, iconColor, title, description, onTap, isLoading, showChevron

2. **CollapsibleSection**
   - Used in: Tasks tab
   - Props: title, count, children, initiallyExpanded

3. **SearchFilterBar**
   - Used in: Upload tab
   - Props: searchController, onFilterPressed, onSearchChanged, hasActiveFilters

4. **AudioPlayerDialog**
   - Used in: Upload tab
   - Props: audioUrl, title

5. **FilterDialog**
   - Used in: Upload tab
   - Props: initialFromDate, initialToDate, onApply

---

## Task Notifications

### Handling Task Item Clicks (Tasks Tab)

When users click on task items in the "Tasks" tab, show a notification instead of performing an action:

```dart
void _showTaskNotification(BuildContext context, String taskType) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('$taskType in progress...'),
      duration: Duration(seconds: 2),
      backgroundColor: Colors.blue,
    ),
  );
}

// Usage in CollapsibleSection:
CommonTaskItem(
  icon: Icons.upload_file,
  iconColor: Colors.orange,
  title: task.filename,
  description: 'Uploading...',
  isLoading: true,
  showChevron: false,
  onTap: () => _showTaskNotification(context, 'Uploading'),
)
```

---

## Dependencies Update

Add to `pubspec.yaml`:

```yaml
dependencies:
  # Existing dependencies...
  
  # Audio playback
  audioplayers: ^5.2.1
  
  # Already included (verify):
  flutter_bloc: ^8.1.3
  equatable: ^2.0.5
  dartz: ^0.10.1
  get_it: ^7.6.4
  dio: ^5.3.3
  file_picker: ^6.1.1
```

---

## Testing Checklist

### Unit Tests
- [ ] Test all use cases
- [ ] Test repository implementations
- [ ] Test BLoC event handlers
- [ ] Test data model serialization

### Widget Tests
- [ ] Test CommonTaskItem widget
- [ ] Test CollapsibleSection expand/collapse
- [ ] Test SearchFilterBar functionality
- [ ] Test tab navigation

### Integration Tests
- [ ] Test complete upload flow
- [ ] Test audio playback
- [ ] Test search and filter
- [ ] Test task monitoring

---

## Implementation Notes

1. **Consistent Theming**: Use existing app colors (background: `0xFF101822`, card: `0xFF282E39`, accent: `0xFF3B82F6`)

2. **Error Handling**: Display user-friendly error messages using SnackBar

3. **Loading States**: Show loading indicators during API calls

4. **Empty States**: Show appropriate empty state messages when no data

5. **Pull to Refresh**: Implement pull-to-refresh on all tabs

6. **Pagination**: Implement pagination for audio file list

7. **Real-time Updates**: Consider using WebSocket or polling for task status updates

8. **Offline Support**: Cache uploaded audio list for offline viewing

9. **File Size Limits**: Validate audio file size before upload

10. **Supported Formats**: Accept common audio formats (MP3, WAV, M4A, AAC, FLAC, OGG)

---

## Next Steps

1. Create domain layer (entities, repositories, use cases)
2. Implement data layer (models, data sources, repository implementation)
3. Build common widgets (CommonTaskItem, CollapsibleSection, etc.)
4. Implement BLoC (events, states, bloc logic)
5. Build tab pages (UploadTab, TasksTab, PendingTab)
6. Create main Audio Manager page with TabBar
7. Implement audio player dialog
8. Implement filter dialog
9. Update dependency injection
10. Update navigation and routing
11. Test complete feature flow
12. Polish UI and animations

---

## Additional Features (Future Enhancements)

- Batch upload multiple audio files
- Download audio files
- Share audio files
- Delete audio files
- Sort options (by date, size, name)
- Audio waveform visualization
- Playback speed control
- Background audio playback
- Offline audio playback (cached files)
- Advanced filtering (by status, duration, etc.)

---

**End of Document**
