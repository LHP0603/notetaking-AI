# Audio Item UI Update - Chevron Right Icon Button

## Overview
Update the audio item UI in both Upload and Pending tabs to consistently display a chevron right icon button on the right side. The click action logic will be implemented later.

## Current Implementation

The `AudioFileListItem` widget currently uses `CommonTaskItem` and conditionally displays either:
- Status icons (completed, processing, failed) when `showStatusIcon = true`
- Chevron icon when `showStatusIcon = false`

## Required Changes

### Objective
All audio items in Upload and Pending tabs should display a **chevron right icon button** on the right side, regardless of their status. The status information can be shown in the description text instead.

### Implementation Steps

#### 1. Update AudioFileListItem Widget

**File**: `lib/features/audio_manager/presentation/widgets/audio_file_list_item.dart`

**Changes**:

1. **Remove the `showStatusIcon` parameter** - No longer needed since we always show chevron
2. **Update the `trailing` property** - Always pass `null` to CommonTaskItem to use default chevron
3. **Update `showChevron` property** - Always set to `true`
4. **Move status information to description** - Include status in the description text instead of icon

**Modified Code**:

```dart
class AudioFileListItem extends StatelessWidget {
  final AudioFile audioFile;
  final VoidCallback? onTap;
  final IconData icon;
  final Color iconColor;
  final bool showPendingStatus;
  // Remove: final bool showStatusIcon;

  const AudioFileListItem({
    super.key,
    required this.audioFile,
    this.onTap,
    this.icon = Icons.audiotrack,
    this.iconColor = const Color(0xFF3B82F6),
    this.showPendingStatus = false,
    // Remove: this.showStatusIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    return CommonTaskItem(
      icon: icon,
      iconColor: iconColor,
      title: audioFile.originalFilename ?? audioFile.filename,
      description: _buildDescription(),
      onTap: onTap ?? () {},
      showChevron: true, // Always show chevron
      trailing: null, // Always null to show default chevron
    );
  }

  String _buildDescription() {
    final parts = <String>[];
    
    // Add duration
    if (audioFile.duration != null) {
      parts.add('Duration ${_formatDuration(audioFile.duration!)}');
    }
    
    // Add status text (moved from icon to description)
    if (audioFile.status != null && audioFile.status!.isNotEmpty) {
      parts.add('Status: ${_formatStatus(audioFile.status!)}');
    }
    
    // Add upload date
    final created = audioFile.createdAt ?? audioFile.uploadDate;
    if (created != null) {
      parts.add('Uploaded ${_formatDate(created)}');
    }
    
    // Add file size
    if (audioFile.fileSize != null) {
      parts.add(_formatBytes(audioFile.fileSize!));
    }
    
    // Add pending status if applicable
    if (showPendingStatus) {
      if (_needsTranscription()) {
        parts.add('⚠️ Needs transcription');
      } else if (_needsSummary()) {
        parts.add('⚠️ Needs summary');
      }
    }
    
    return parts.isEmpty ? 'Tap to view' : parts.join(' • ');
  }

  // Remove the _buildTrailing() method - no longer needed

  bool _needsTranscription() {
    return audioFile.transcription == null || audioFile.transcription!.isEmpty;
  }

  bool _needsSummary() {
    final summarized = audioFile.isSummarize ?? audioFile.hasSummary;
    return summarized == false && !_needsTranscription();
  }

  String _formatDuration(double seconds) {
    final duration = Duration(seconds: seconds.round());
    final minutes = duration.inMinutes;
    final remainingSeconds = duration.inSeconds.remainder(60);
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  String _formatBytes(int bytes) {
    final mb = bytes / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }

  String _formatStatus(String status) {
    final normalized = status.trim().toLowerCase();
    if (normalized.isEmpty) {
      return 'Unknown';
    }
    final words = normalized.replaceAll(RegExp(r'[_-]+'), ' ').split(' ');
    return words
        .where((word) => word.isNotEmpty)
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}
```

#### 2. Update Usage in Upload Tab

**File**: `lib/features/audio_manager/presentation/pages/audio_upload_tab.dart` (or wherever AudioFileListItem is used)

**Before**:
```dart
AudioFileListItem(
  audioFile: audioFiles[index],
  showStatusIcon: true, // Remove this parameter
  onTap: () {
    // Navigation logic will be implemented later
  },
)
```

**After**:
```dart
AudioFileListItem(
  audioFile: audioFiles[index],
  onTap: () {
    // TODO: Navigate to audio detail screen
    // This will be implemented later
  },
)
```

#### 3. Update Usage in Pending Tab

**File**: `lib/features/audio_manager/presentation/pages/audio_pending_tab.dart` (or wherever AudioFileListItem is used)

**Before**:
```dart
AudioFileListItem(
  audioFile: audio,
  showPendingStatus: true,
  showStatusIcon: false, // Remove this parameter
  onTap: () {
    // Navigation logic
  },
)
```

**After**:
```dart
AudioFileListItem(
  audioFile: audio,
  showPendingStatus: true, // Keep this to show pending status text
  onTap: () {
    // TODO: Navigate to audio detail screen
    // This will be implemented later
  },
)
```

#### 4. Verify CommonTaskItem Implementation

Ensure that `CommonTaskItem` properly handles the chevron icon button:

**File**: `lib/features/audio_manager/presentation/widgets/common_task_item.dart`

**Required behavior**:
- When `showChevron = true` and `trailing = null`, display chevron right icon
- The chevron should be clickable and trigger the `onTap` callback
- Icon should be `Icons.chevron_right`
- Color should be neutral (e.g., `Colors.grey[600]`)

**Example implementation** (if not already present):
```dart
class CommonTaskItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final VoidCallback onTap;
  final bool showChevron;
  final Widget? trailing;

  const CommonTaskItem({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.onTap,
    this.showChevron = true,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
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
              Icon(
                Icons.chevron_right,
                color: Colors.grey[600],
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}
```

## Visual Changes

### Before
- Upload tab: Shows status icons (✓ for completed, ⟳ for processing, ✗ for failed)
- Pending tab: Shows specific icons (description icon, summarize icon)

### After
- Upload tab: Shows chevron right (›) for all items
- Pending tab: Shows chevron right (›) for all items
- Status information moved to description text with emoji indicators (⚠️ for pending actions)

## Benefits

1. **Consistency**: All audio items have the same visual pattern
2. **Clarity**: Chevron indicates the item is tappable and will navigate to details
3. **Flexibility**: Status information in text is more descriptive than icons
4. **Future-proof**: Ready for detail screen navigation implementation

## Testing Checklist

- [ ] Upload tab displays chevron right for all audio items
- [ ] Pending tab displays chevron right for all audio items
- [ ] Status information appears correctly in description text
- [ ] Pending status (needs transcription/summary) shows in description with emoji
- [ ] Tapping on audio item triggers onTap callback
- [ ] Visual appearance is consistent across both tabs
- [ ] Description text doesn't overflow or get cut off
- [ ] Chevron icon is properly aligned vertically

## Future Implementation

The `onTap` callback is currently a placeholder. In future implementations, it should:
- Navigate to an audio detail screen
- Pass the `audioFile` object to the detail screen
- Display full audio information, transcription, and summary
- Provide audio playback controls
- Allow editing or deleting the audio file

Example future implementation:
```dart
AudioFileListItem(
  audioFile: audioFiles[index],
  onTap: () {
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

## Notes

- If status icons are needed in the future, consider adding status badges or chips to the description area
- The emoji indicators (⚠️) for pending status provide visual cues without requiring custom icons
- Consider adding haptic feedback on tap for better user experience
- Ensure the entire item area is tappable, not just the chevron icon
