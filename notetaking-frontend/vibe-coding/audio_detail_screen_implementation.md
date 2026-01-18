# Audio Detail Screen - Transcript and Summary Editor

## Overview
This document provides implementation instructions for the Audio Detail Screen, which displays and allows editing of audio transcriptions and summaries. The screen is accessed by tapping the chevron right button on any audio item.

**Note**: This implementation focuses on **UI only**. API integration will be implemented later.

## Feature Requirements

### 1. Navigation

**Entry Point**: User taps the **chevron right button** on an audio item in Upload or Pending tabs

**IMPORTANT**: 
- **DO NOT** replace the existing `onTap` behavior (which likely plays audio)
- The chevron button should have its own separate tap handler
- Only clicking the chevron navigates to the detail screen
- Clicking the audio item itself should keep the current behavior (play audio)

#### Update CommonTaskItem Widget

First, modify `CommonTaskItem` to support a separate chevron tap handler:

**File**: `lib/features/audio_manager/presentation/widgets/common_task_item.dart`

```dart
class CommonTaskItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final VoidCallback onTap;
  final bool showChevron;
  final Widget? trailing;
  final VoidCallback? onChevronTap; // NEW: Separate handler for chevron

  const CommonTaskItem({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.onTap,
    this.showChevron = true,
    this.trailing,
    this.onChevronTap, // NEW: Add this parameter
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap, // Main item tap (e.g., play audio)
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Leading icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 12),
            
            // Title and description
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
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
              IconButton(
                icon: Icon(
                  Icons.chevron_right,
                  color: Colors.grey[600],
                  size: 24,
                ),
                onPressed: onChevronTap ?? onTap, // Use chevron handler if provided
                padding: EdgeInsets.all(8),
              ),
          ],
        ),
      ),
    );
  }
}
```

#### Update AudioFileListItem Widget

Then update `AudioFileListItem` to accept and pass through the chevron tap handler:

**File**: `lib/features/audio_manager/presentation/widgets/audio_file_list_item.dart`

```dart
class AudioFileListItem extends StatelessWidget {
  final AudioFile audioFile;
  final VoidCallback? onTap; // Main item tap (e.g., play audio)
  final VoidCallback? onChevronTap; // NEW: Chevron tap (navigate to detail)
  final IconData icon;
  final Color iconColor;
  final bool showPendingStatus;

  const AudioFileListItem({
    super.key,
    required this.audioFile,
    this.onTap,
    this.onChevronTap, // NEW: Add this parameter
    this.icon = Icons.audiotrack,
    this.iconColor = const Color(0xFF3B82F6),
    this.showPendingStatus = false,
  });

  @override
  Widget build(BuildContext context) {
    return CommonTaskItem(
      icon: icon,
      iconColor: iconColor,
      title: audioFile.originalFilename ?? audioFile.filename,
      description: _buildDescription(),
      onTap: onTap ?? () {}, // Main tap - keep existing behavior
      onChevronTap: onChevronTap, // NEW: Pass chevron handler
      showChevron: true,
      trailing: null,
    );
  }
  
  // ... rest of the widget remains the same
}
```

#### Usage in Upload/Pending Tabs

**Navigation Code**:
```dart
AudioFileListItem(
  audioFile: audioFiles[index],
  onTap: () {
    // KEEP EXISTING LOGIC - e.g., play audio
    _playAudio(audioFiles[index]);
  },
  onChevronTap: () {
    // NEW: Navigate to detail screen only when chevron is tapped
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AudioDetailScreen(
          audioFile: audioFiles[index],
        ),
      ),
    );
  },
)
```

### 2. AppBar Configuration

#### AppBar Elements

**Title**: Audio filename (from `audioFile.originalFilename` or `audioFile.filename`)

**Leading (Left)**: Back button (chevron left)
```dart
leading: IconButton(
  icon: Icon(Icons.chevron_left),
  onPressed: () => _handleBackPressed(context),
)
```

**Actions (Right)**: Three-dot menu button
```dart
actions: [
  PopupMenuButton<AudioMenuAction>(
    icon: Icon(Icons.more_vert),
    onSelected: (action) => _handleMenuAction(context, action),
    itemBuilder: (context) => [
      PopupMenuItem(
        value: AudioMenuAction.rename,
        child: Row(
          children: [
            Icon(Icons.edit),
            SizedBox(width: 12),
            Text('Rename Audio'),
          ],
        ),
      ),
      PopupMenuItem(
        value: AudioMenuAction.delete,
        child: Row(
          children: [
            Icon(Icons.delete, color: Colors.red),
            SizedBox(width: 12),
            Text('Delete Audio', style: TextStyle(color: Colors.red)),
          ],
        ),
      ),
      PopupMenuItem(
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
]
```

#### Menu Actions

**Enum Definition**:
```dart
enum AudioMenuAction {
  rename,
  delete,
  download,
}
```

**Rename Action**: Show dialog with text input
```dart
void _showRenameDialog(BuildContext context) {
  final controller = TextEditingController(text: currentFilename);
  
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
          onPressed: () {
            final newName = controller.text.trim();
            if (newName.isNotEmpty) {
              // TODO: Implement rename logic with API
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Renamed to: $newName')),
              );
            }
          },
          child: Text('Rename'),
        ),
      ],
    ),
  );
}
```

**Delete Action**: Show confirmation dialog
```dart
void _showDeleteConfirmation(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Delete Audio'),
      content: Text('Are you sure you want to delete this audio? This action cannot be undone.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            // TODO: Implement delete logic with API
            Navigator.pop(context); // Close dialog
            Navigator.pop(context); // Go back to previous screen
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Audio deleted successfully')),
            );
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
```

**Download Action**: Trigger download
```dart
void _handleDownload(BuildContext context) {
  // TODO: Implement download logic with API
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Download started...')),
  );
}
```

### 3. Tab Structure

#### Tab Configuration

The screen has two tabs: **Transcription** and **Summary**

**Summary tab is disabled** when audio doesn't have a transcript.

```dart
class AudioDetailScreen extends StatefulWidget {
  final AudioFile audioFile;

  const AudioDetailScreen({
    Key? key,
    required this.audioFile,
  }) : super(key: key);

  @override
  State<AudioDetailScreen> createState() => _AudioDetailScreenState();
}

class _AudioDetailScreenState extends State<AudioDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _hasUnsavedChanges = false;
  
  // Mock data - replace with actual API data later
  bool get _hasTranscript => widget.audioFile.transcription != null;
  bool get _hasSummary => widget.audioFile.isSummarize ?? false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
    );
    
    // Prevent switching to Summary tab if no transcript
    _tabController.addListener(() {
      if (_tabController.index == 1 && !_hasTranscript) {
        _tabController.index = 0;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please transcribe the audio first'),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () => _handleBackPressed(context),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.audioFile.originalFilename ?? 
            widget.audioFile.filename ?? 
            'Audio Details',
            overflow: TextOverflow.ellipsis,
          ),
          leading: IconButton(
            icon: Icon(Icons.chevron_left),
            onPressed: () => _handleBackPressed(context),
          ),
          actions: [
            PopupMenuButton<AudioMenuAction>(
              icon: Icon(Icons.more_vert),
              onSelected: _handleMenuAction,
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: AudioMenuAction.rename,
                  child: Row(
                    children: [
                      Icon(Icons.edit),
                      SizedBox(width: 12),
                      Text('Rename Audio'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: AudioMenuAction.delete,
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 12),
                      Text('Delete Audio', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
                PopupMenuItem(
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
            tabs: [
              Tab(text: 'Transcription'),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Summary'),
                    if (!_hasTranscript) ...[
                      SizedBox(width: 8),
                      Icon(Icons.lock, size: 16),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          physics: _hasTranscript 
              ? null 
              : NeverScrollableScrollPhysics(), // Disable swipe if no transcript
          children: [
            TranscriptionTab(
              audioFile: widget.audioFile,
              hasTranscript: _hasTranscript,
              onChanged: () => setState(() => _hasUnsavedChanges = true),
            ),
            SummaryTab(
              audioFile: widget.audioFile,
              hasSummary: _hasSummary,
              enabled: _hasTranscript,
              onChanged: () => setState(() => _hasUnsavedChanges = true),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _handleBackPressed(BuildContext context) async {
    if (_hasUnsavedChanges) {
      final shouldExit = await _showUnsavedChangesDialog(context);
      return shouldExit ?? false;
    }
    return true;
  }

  Future<bool?> _showUnsavedChangesDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Unsaved Changes'),
        content: Text('You have unsaved changes. Do you want to save before leaving?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, true), // Exit without saving
            child: Text('Discard'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, false), // Don't exit
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Save changes
              Navigator.pop(context, true); // Exit after saving
            },
            child: Text('Save'),
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

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
```

### 4. Transcription Tab

#### UI States

**State 1: No Transcript**
- Display message informing user the audio hasn't been transcribed
- Show button to trigger transcription

**State 2: Has Transcript**
- Display editable text field with transcript content
- Show save button at bottom (hidden when keyboard is visible)

#### Implementation

```dart
class TranscriptionTab extends StatefulWidget {
  final AudioFile audioFile;
  final bool hasTranscript;
  final VoidCallback onChanged;

  const TranscriptionTab({
    Key? key,
    required this.audioFile,
    required this.hasTranscript,
    required this.onChanged,
  }) : super(key: key);

  @override
  State<TranscriptionTab> createState() => _TranscriptionTabState();
}

class _TranscriptionTabState extends State<TranscriptionTab> {
  late TextEditingController _controller;
  bool _isKeyboardVisible = false;
  String _initialText = '';

  @override
  void initState() {
    super.initState();
    _initialText = widget.audioFile.transcription ?? '';
    _controller = TextEditingController(text: _initialText);
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    if (_controller.text != _initialText) {
      widget.onChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if keyboard is visible
    _isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    if (!widget.hasTranscript) {
      return _buildNoTranscriptView();
    }

    return _buildTranscriptEditor();
  }

  Widget _buildNoTranscriptView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined,
              size: 80,
              color: Colors.grey,
            ),
            SizedBox(height: 24),
            Text(
              'No Transcript Available',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'This audio has not been transcribed yet. Click the button below to start transcription.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _handleTranscribe,
              icon: Icon(Icons.transcribe),
              label: Text('Transcribe Audio'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTranscriptEditor() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: TextField(
              controller: _controller,
              maxLines: null,
              decoration: InputDecoration(
                hintText: 'Transcript content...',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.all(16),
              ),
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
          ),
        ),
        if (!_isKeyboardVisible)
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _handleSave,
                  child: Text('Save Transcript'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _handleTranscribe() {
    // TODO: Implement API call to start transcription
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Transcription started...')),
    );
  }

  void _handleSave() {
    // TODO: Implement API call to save transcript
    _initialText = _controller.text;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Transcript saved successfully')),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

### 5. Summary Tab

#### Requirements
- Use **flutter_quill** package for rich text editing
- Only accessible when transcript exists
- Display rich text from API response
- Editable with save button at bottom (hidden when keyboard is visible)

#### Dependencies

Add to `pubspec.yaml`:
```yaml
dependencies:
  flutter_quill: ^9.0.0
```

#### Implementation

```dart
import 'package:flutter_quill/flutter_quill.dart' as quill;

class SummaryTab extends StatefulWidget {
  final AudioFile audioFile;
  final bool hasSummary;
  final bool enabled;
  final VoidCallback onChanged;

  const SummaryTab({
    Key? key,
    required this.audioFile,
    required this.hasSummary,
    required this.enabled,
    required this.onChanged,
  }) : super(key: key);

  @override
  State<SummaryTab> createState() => _SummaryTabState();
}

class _SummaryTabState extends State<SummaryTab> {
  late quill.QuillController _controller;
  bool _isKeyboardVisible = false;
  String _initialContent = '';

  @override
  void initState() {
    super.initState();
    _initializeQuillController();
  }

  void _initializeQuillController() {
    // TODO: Load summary from API and convert to Quill Delta format
    // For now, use mock data or empty document
    if (widget.hasSummary && widget.audioFile.summary != null) {
      // If summary is in JSON format (Delta), parse it
      // _controller = quill.QuillController(
      //   document: quill.Document.fromJson(jsonDecode(widget.audioFile.summary)),
      //   selection: TextSelection.collapsed(offset: 0),
      // );
      
      // For plain text summary:
      final doc = quill.Document()..insert(0, widget.audioFile.summary ?? '');
      _controller = quill.QuillController(
        document: doc,
        selection: TextSelection.collapsed(offset: 0),
      );
    } else {
      _controller = quill.QuillController.basic();
    }

    _controller.addListener(_onContentChanged);
    _initialContent = _getDocumentContent();
  }

  String _getDocumentContent() {
    return _controller.document.toPlainText();
  }

  void _onContentChanged() {
    final currentContent = _getDocumentContent();
    if (currentContent != _initialContent) {
      widget.onChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    _isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    if (!widget.enabled) {
      return _buildDisabledView();
    }

    if (!widget.hasSummary) {
      return _buildNoSummaryView();
    }

    return _buildSummaryEditor();
  }

  Widget _buildDisabledView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock,
              size: 80,
              color: Colors.grey,
            ),
            SizedBox(height: 24),
            Text(
              'Summary Not Available',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Please transcribe the audio first before generating a summary.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoSummaryView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.summarize,
              size: 80,
              color: Colors.grey,
            ),
            SizedBox(height: 24),
            Text(
              'No Summary Available',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'This audio has not been summarized yet. Click the button below to generate a summary.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _handleGenerateSummary,
              icon: Icon(Icons.auto_awesome),
              label: Text('Generate Summary'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryEditor() {
    return Column(
      children: [
        // Toolbar
        if (!_isKeyboardVisible)
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(
                bottom: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: quill.QuillToolbar.simple(
              configurations: quill.QuillSimpleToolbarConfigurations(
                controller: _controller,
                sharedConfigurations: const quill.QuillSharedConfigurations(),
              ),
            ),
          ),
        
        // Editor
        Expanded(
          child: Container(
            padding: EdgeInsets.all(16),
            child: quill.QuillEditor.basic(
              configurations: quill.QuillEditorConfigurations(
                controller: _controller,
                sharedConfigurations: const quill.QuillSharedConfigurations(),
                placeholder: 'Summary content...',
              ),
            ),
          ),
        ),
        
        // Save Button
        if (!_isKeyboardVisible)
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _handleSave,
                  child: Text('Save Summary'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _handleGenerateSummary() {
    // TODO: Implement API call to generate summary
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Generating summary...')),
    );
  }

  void _handleSave() {
    // TODO: Implement API call to save summary
    // Convert Quill document to JSON for API
    // final delta = _controller.document.toDelta();
    // final json = jsonEncode(delta.toJson());
    
    _initialContent = _getDocumentContent();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Summary saved successfully')),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

### 6. AudioFile Entity Updates

Ensure the `AudioFile` entity has a `summary` field:

```dart
class AudioFile {
  final int id;
  final String? filename;
  final String? originalFilename;
  final String? transcription;
  final bool? isSummarize;
  final String? summary; // Add this field for summary content
  // ... other fields

  const AudioFile({
    required this.id,
    this.filename,
    this.originalFilename,
    this.transcription,
    this.isSummarize,
    this.summary, // Add this field
    // ... other fields
  });

  factory AudioFile.fromJson(Map<String, dynamic> json) {
    return AudioFile(
      id: json['id'] as int,
      filename: json['filename'] as String?,
      originalFilename: json['original_filename'] as String?,
      transcription: json['transcription'] as String?,
      isSummarize: json['is_summarize'] as bool?,
      summary: json['summary'] as String?, // Parse summary field
      // ... other fields
    );
  }
}
```

## File Structure

```
lib/
├── features/
│   └── audio_manager/
│       ├── domain/
│       │   └── entities/
│       │       └── audio_file.dart (update with summary field)
│       └── presentation/
│           ├── pages/
│           │   ├── audio_detail_screen.dart (main screen)
│           │   ├── transcription_tab.dart
│           │   └── summary_tab.dart
│           └── widgets/
│               └── audio_file_list_item.dart (update onTap)
```

## Implementation Checklist

### Core Screen
- [ ] Create `AudioDetailScreen` widget
- [ ] Implement AppBar with title, back button, and menu
- [ ] Add TabController with 2 tabs
- [ ] Implement WillPopScope for back button handling
- [ ] Add unsaved changes tracking

### AppBar Menu
- [ ] Create `AudioMenuAction` enum
- [ ] Implement PopupMenuButton with 3 options
- [ ] Create rename dialog with text input
- [ ] Create delete confirmation dialog
- [ ] Implement download action placeholder

### Transcription Tab
- [ ] Create `TranscriptionTab` widget
- [ ] Implement "no transcript" view with message and button
- [ ] Implement transcript editor with TextField
- [ ] Add keyboard visibility detection
- [ ] Add save button (hidden when keyboard visible)
- [ ] Track text changes for unsaved state

### Summary Tab
- [ ] Add flutter_quill dependency to pubspec.yaml
- [ ] Create `SummaryTab` widget
- [ ] Implement disabled view (when no transcript)
- [ ] Implement "no summary" view with generate button
- [ ] Implement QuillEditor with toolbar
- [ ] Add save button (hidden when keyboard visible)
- [ ] Track content changes for unsaved state

### Navigation & State
- [ ] Update AudioFileListItem onTap to navigate to detail screen
- [ ] Implement unsaved changes dialog
- [ ] Disable Summary tab when no transcript exists
- [ ] Prevent tab switching to Summary without transcript

### Data Layer
- [ ] Add `summary` field to AudioFile entity
- [ ] Update AudioFile.fromJson to parse summary

## Testing Checklist

### Navigation
- [ ] Clicking audio item navigates to detail screen
- [ ] Back button shows unsaved changes dialog if applicable
- [ ] Back button exits without dialog if no changes

### AppBar Menu
- [ ] Menu opens with 3 options
- [ ] Rename dialog shows with current filename
- [ ] Rename saves new name (mocked for now)
- [ ] Delete shows confirmation dialog
- [ ] Delete confirms and goes back (mocked for now)
- [ ] Download triggers action (mocked for now)

### Transcription Tab
- [ ] Shows "no transcript" view when transcript is null
- [ ] Transcribe button triggers action (mocked)
- [ ] Shows editor when transcript exists
- [ ] Text is editable
- [ ] Save button visible when keyboard hidden
- [ ] Save button hidden when keyboard visible
- [ ] Changes are tracked for unsaved state

### Summary Tab
- [ ] Tab is disabled/locked when no transcript
- [ ] Shows disabled view when no transcript
- [ ] Shows "no summary" view when transcript exists but no summary
- [ ] Generate button triggers action (mocked)
- [ ] Shows QuillEditor when summary exists
- [ ] Toolbar visible when keyboard hidden
- [ ] Rich text editing works
- [ ] Save button visible when keyboard hidden
- [ ] Save button hidden when keyboard visible
- [ ] Changes are tracked for unsaved state

### Unsaved Changes
- [ ] Dialog shows when exiting with unsaved changes
- [ ] Discard button exits without saving
- [ ] Cancel button stays on screen
- [ ] Save button saves and exits (mocked)

## Future API Integration

When implementing API calls, replace the TODO comments with actual implementations:

### Rename Audio
```dart
// POST /audio/{id}/rename
// Body: { "new_filename": "string" }
```

### Delete Audio
```dart
// DELETE /audio/{id}
```

### Download Audio
```dart
// GET /audio/{id}/download
// Returns audio file
```

### Start Transcription
```dart
// POST /audio/{id}/transcribe
// Triggers async transcription process
```

### Save Transcript
```dart
// PUT /audio/{id}/transcript
// Body: { "transcription": "string" }
```

### Generate Summary
```dart
// POST /audio/{id}/summarize
// Triggers async summarization process
```

### Save Summary
```dart
// PUT /audio/{id}/summary
// Body: { "summary": "string" or Delta JSON }
```

## Notes

- The keyboard visibility detection uses `MediaQuery.of(context).viewInsets.bottom`
- flutter_quill supports Delta format for rich text, which should be compatible with most backend formats
- Consider adding loading states for all async operations
- Consider adding optimistic UI updates for better UX
- May want to add auto-save functionality with debouncing
- Consider adding a "discard changes" option in the menu
- May want to show word count or character count in editors
