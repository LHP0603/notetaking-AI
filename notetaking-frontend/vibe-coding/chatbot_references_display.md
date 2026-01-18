# Chatbot References Display Implementation Guide

## Overview
This guide describes how to display and handle chatbot message references (audio files and notes) in chat responses. When the AI assistant references audio files or notes, users should be able to tap on them to navigate to the corresponding detail screens.

## Response Structure

### Task Status Response (Chatbot Message Completed)
```
GET /tasks/jobs/{job_id}
```

#### Response Payload
```json
{
  "code": 200,
  "success": true,
  "message": "Job status retrieved successfully",
  "data": {
    "job_id": "uuid",
    "task_type": "chatbot_message",
    "status": "completed",
    "result": {
      "message_id": "uuid",
      "response": "Mình tìm thấy 2 bản ghi âm phù hợp.",
      "intent": "search",
      "audio_references": [
        {
          "audio_id": 30,
          "title": "transcripted audio",
          "duration": 2403.024,
          "created_at": "2025-12-27T01:31:00.676251"
        },
        {
          "audio_id": 12,
          "title": "Audio file title",
          "duration": 7046.791837,
          "created_at": "2025-12-25T08:56:24.329257"
        }
      ],
      "note_references": [
        {
          "note_id": 12,
          "title": "transcripted audio"
        },
        {
          "note_id": 10,
          "title": "Note title"
        }
      ],
      "suggested_questions": [
        "Bạn có muốn tóm tắt các bản ghi này không?",
        "Cho mình xem bản gần nhất."
      ]
    },
    "error_message": null,
    "created_at": "2025-12-27T03:01:09.054771",
    "updated_at": "2025-12-27T03:01:16.013626"
  }
}
```

## Data Models

### ChatMessage Entity (Enhanced)
```dart
class ChatMessage extends Equatable {
  final String messageId;
  final String role; // 'user' or 'assistant'
  final String content;
  final String? intent;
  final List<AudioReference>? audioReferences;
  final List<NoteReference>? noteReferences;
  final List<String>? suggestedQuestions;
  final DateTime createdAt;

  const ChatMessage({
    required this.messageId,
    required this.role,
    required this.content,
    this.intent,
    this.audioReferences,
    this.noteReferences,
    this.suggestedQuestions,
    required this.createdAt,
  });

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';
  bool get hasReferences => 
    (audioReferences?.isNotEmpty ?? false) || 
    (noteReferences?.isNotEmpty ?? false);

  @override
  List<Object?> get props => [
    messageId,
    role,
    content,
    intent,
    audioReferences,
    noteReferences,
    suggestedQuestions,
    createdAt,
  ];
}
```

### AudioReference Entity
```dart
class AudioReference extends Equatable {
  final int audioId;
  final String title;
  final double duration;
  final DateTime createdAt;

  const AudioReference({
    required this.audioId,
    required this.title,
    required this.duration,
    required this.createdAt,
  });

  String get formattedDuration {
    final totalSeconds = duration.toInt();
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    
    if (hours > 0) {
      return '${hours}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  List<Object?> get props => [audioId, title, duration, createdAt];
}
```

### NoteReference Entity
```dart
class NoteReference extends Equatable {
  final int noteId;
  final String title;

  const NoteReference({
    required this.noteId,
    required this.title,
  });

  @override
  List<Object?> get props => [noteId, title];
}
```

## Model Classes (fromJson)

### ChatMessageModel
```dart
factory ChatMessageModel.fromJobResult(Map<String, dynamic> result) {
  List<AudioReference>? audioRefs;
  if (result['audio_references'] != null) {
    audioRefs = (result['audio_references'] as List)
        .map((item) => AudioReferenceModel.fromJson(item))
        .toList();
  }

  List<NoteReference>? noteRefs;
  if (result['note_references'] != null) {
    noteRefs = (result['note_references'] as List)
        .map((item) => NoteReferenceModel.fromJson(item))
        .toList();
  }

  List<String>? suggestions;
  if (result['suggested_questions'] != null) {
    suggestions = (result['suggested_questions'] as List)
        .map((item) => item.toString())
        .toList();
  }

  return ChatMessageModel(
    messageId: result['message_id']?.toString() ?? '',
    role: 'assistant',
    content: result['response']?.toString() ?? '',
    intent: result['intent']?.toString(),
    audioReferences: audioRefs,
    noteReferences: noteRefs,
    suggestedQuestions: suggestions,
    createdAt: DateTime.now(),
  );
}
```

### AudioReferenceModel
```dart
class AudioReferenceModel extends AudioReference {
  const AudioReferenceModel({
    required super.audioId,
    required super.title,
    required super.duration,
    required super.createdAt,
  });

  factory AudioReferenceModel.fromJson(Map<String, dynamic> json) {
    return AudioReferenceModel(
      audioId: json['audio_id'] as int,
      title: json['title']?.toString() ?? '',
      duration: (json['duration'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'].toString()),
    );
  }
}
```

### NoteReferenceModel
```dart
class NoteReferenceModel extends NoteReference {
  const NoteReferenceModel({
    required super.noteId,
    required super.title,
  });

  factory NoteReferenceModel.fromJson(Map<String, dynamic> json) {
    return NoteReferenceModel(
      noteId: json['note_id'] as int,
      title: json['title']?.toString() ?? '',
    );
  }
}
```

## UI Components

### Message Widget with References

#### Custom Message Widget Structure
```dart
class ChatMessageBubble extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback? onAudioTap;
  final VoidCallback? onNoteTap;

  const ChatMessageBubble({
    Key? key,
    required this.message,
    this.onAudioTap,
    this.onNoteTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: message.isUser 
        ? CrossAxisAlignment.end 
        : CrossAxisAlignment.start,
      children: [
        // Main message bubble
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: message.isUser 
              ? const Color(0xFF3B82F6) 
              : Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            message.content,
            style: TextStyle(
              color: message.isUser ? Colors.white : Colors.black87,
            ),
          ),
        ),
        
        // Audio references
        if (message.audioReferences?.isNotEmpty ?? false)
          _buildAudioReferences(context),
        
        // Note references
        if (message.noteReferences?.isNotEmpty ?? false)
          _buildNoteReferences(context),
        
        // Suggested questions
        if (message.suggestedQuestions?.isNotEmpty ?? false)
          _buildSuggestedQuestions(context),
      ],
    );
  }
}
```

### Audio Reference Card
```dart
Widget _buildAudioReferences(BuildContext context) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 8),
      ...message.audioReferences!.map((audio) => 
        _buildAudioCard(context, audio)
      ),
    ],
  );
}

Widget _buildAudioCard(BuildContext context, AudioReference audio) {
  return Card(
    margin: const EdgeInsets.only(top: 4, bottom: 4),
    child: InkWell(
      onTap: () => _navigateToAudioDetail(context, audio.audioId),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Audio icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.audio_file,
                color: Color(0xFF3B82F6),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            
            // Audio info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    audio.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    audio.formattedDuration,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            
            // Chevron icon
            Icon(
              Icons.chevron_right,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    ),
  );
}

void _navigateToAudioDetail(BuildContext context, int audioId) {
  // TODO: Implement navigation to audio detail screen
  // This should fetch the full AudioFile by ID and navigate
  Navigator.pushNamed(
    context,
    '/audio-detail',
    arguments: audioId,
  );
  
  // OR using GoRouter:
  // context.push('/audio/$audioId');
}
```

### Note Reference Card
```dart
Widget _buildNoteReferences(BuildContext context) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 8),
      ...message.noteReferences!.map((note) => 
        _buildNoteCard(context, note)
      ),
    ],
  );
}

Widget _buildNoteCard(BuildContext context, NoteReference note) {
  return Card(
    margin: const EdgeInsets.only(top: 4, bottom: 4),
    child: InkWell(
      onTap: () => _navigateToNoteDetail(context, note.noteId),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Note icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.note,
                color: Colors.amber,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            
            // Note title
            Expanded(
              child: Text(
                note.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            
            // Chevron icon
            Icon(
              Icons.chevron_right,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    ),
  );
}

void _navigateToNoteDetail(BuildContext context, int noteId) {
  // TODO: Implement navigation to note detail screen
  // This might navigate to summary tab of the audio that contains this note
}
```

### Suggested Questions Chips
```dart
Widget _buildSuggestedQuestions(BuildContext context) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 12),
      Text(
        'Suggested questions:',
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[600],
          fontWeight: FontWeight.w500,
        ),
      ),
      const SizedBox(height: 6),
      Wrap(
        spacing: 6,
        runSpacing: 6,
        children: message.suggestedQuestions!.map((question) {
          return ActionChip(
            label: Text(
              question,
              style: const TextStyle(fontSize: 12),
            ),
            onPressed: () => _handleSuggestedQuestion(context, question),
            backgroundColor: Colors.grey[100],
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          );
        }).toList(),
      ),
    ],
  );
}

void _handleSuggestedQuestion(BuildContext context, String question) {
  // Send this question as a new message
  // Example: context.read<ChatBloc>().add(SendMessage(question));
}
```

## Navigation Implementation

### Option 1: Using Named Routes

#### Define Route in app router
```dart
// In main.dart or router configuration
MaterialApp(
  routes: {
    '/audio-detail': (context) {
      final audioId = ModalRoute.of(context)!.settings.arguments as int;
      return AudioDetailScreen(audioId: audioId);
    },
  },
);
```

#### Navigate with arguments
```dart
void _navigateToAudioDetail(BuildContext context, int audioId) {
  Navigator.pushNamed(
    context,
    '/audio-detail',
    arguments: audioId,
  );
}
```

### Option 2: Using GoRouter (Recommended)

#### Define route
```dart
// In router configuration
GoRoute(
  path: '/audio/:audioId',
  builder: (context, state) {
    final audioId = int.parse(state.pathParameters['audioId']!);
    return AudioDetailScreen(audioId: audioId);
  },
),
```

#### Navigate
```dart
void _navigateToAudioDetail(BuildContext context, int audioId) {
  context.push('/audio/$audioId');
}
```

### Option 3: Fetch AudioFile first, then navigate

This is the current pattern in the app:

```dart
Future<void> _navigateToAudioDetail(BuildContext context, int audioId) async {
  // Show loading indicator
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const Center(
      child: CircularProgressIndicator(),
    ),
  );

  // Fetch audio file details
  final repository = sl<AudioManagerRepository>();
  final result = await repository.getAudioFileById(audioId);

  if (!context.mounted) return;
  
  // Close loading dialog
  Navigator.pop(context);

  result.fold(
    (failure) {
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load audio: ${failure.message}')),
      );
    },
    (audioFile) {
      // Navigate to detail screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AudioDetailScreen(audioFile: audioFile),
        ),
      );
    },
  );
}
```

## Integration with flutter_chat_ui

### Custom Message Builder
```dart
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

Widget _customMessageBuilder(
  types.Message message,
  {required int messageWidth}
) {
  if (message is types.CustomMessage) {
    final chatMessage = message.metadata?['chatMessage'] as ChatMessage?;
    if (chatMessage != null) {
      return ChatMessageBubble(
        message: chatMessage,
        onAudioTap: () => _navigateToAudioDetail(context, audioId),
      );
    }
  }
  
  // Default text message
  return TextMessage(message: message as types.TextMessage);
}

// In Chat widget
Chat(
  messages: _messages,
  onSendPressed: _handleSendPressed,
  user: _user,
  customMessageBuilder: _customMessageBuilder,
)
```

### Convert ChatMessage to types.CustomMessage
```dart
types.CustomMessage _toFlutterChatMessage(ChatMessage message) {
  return types.CustomMessage(
    author: types.User(
      id: message.isUser ? 'user' : 'assistant',
      firstName: message.isUser ? 'You' : 'AI Assistant',
    ),
    createdAt: message.createdAt.millisecondsSinceEpoch,
    id: message.messageId,
    metadata: {
      'chatMessage': message,
    },
  );
}
```

## Implementation Checklist

### Phase 1: Data Models
- [ ] Create `AudioReference` entity
- [ ] Create `NoteReference` entity
- [ ] Create `AudioReferenceModel` with `fromJson`
- [ ] Create `NoteReferenceModel` with `fromJson`
- [ ] Update `ChatMessage` entity to include references and suggested questions
- [ ] Update `ChatMessageModel.fromJobResult()` to parse references

### Phase 2: UI Components
- [ ] Create `ChatMessageBubble` widget
- [ ] Create `_buildAudioCard()` widget
- [ ] Create `_buildNoteCard()` widget
- [ ] Create `_buildSuggestedQuestions()` widget
- [ ] Add `formattedDuration` getter to `AudioReference`

### Phase 3: Navigation
- [ ] Implement `_navigateToAudioDetail()` method
- [ ] Implement `_navigateToNoteDetail()` method
- [ ] Add route configuration (if using GoRouter)
- [ ] Test navigation with loading states
- [ ] Handle navigation errors gracefully

### Phase 4: Integration
- [ ] Integrate custom message builder with flutter_chat_ui
- [ ] Update chat screen to use new message format
- [ ] Test with different message types (with/without references)
- [ ] Add loading states when fetching audio details
- [ ] Implement suggested questions tap handler

### Phase 5: Polish
- [ ] Add animations for reference cards
- [ ] Implement long-press menu (copy, share, etc.)
- [ ] Add accessibility labels
- [ ] Test on different screen sizes
- [ ] Add haptic feedback on tap

## Visual Design Suggestions

### Audio Reference Card Style
```
┌─────────────────────────────────────────┐
│  🎵  transcripted audio                 │
│      2:34                              › │
└─────────────────────────────────────────┘
```

### Note Reference Card Style
```
┌─────────────────────────────────────────┐
│  📝  Note title here                    │
│                                        › │
└─────────────────────────────────────────┘
```

### Message with References Layout
```
┌─────────────────────────────────────────┐
│ Mình tìm thấy 2 bản ghi âm phù hợp.     │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│  🎵  Audio 1                           › │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│  🎵  Audio 2                           › │
└─────────────────────────────────────────┘

Suggested questions:
[ Bạn có muốn tóm tắt? ] [ Xem bản gần nhất ]
```

## Error Handling

### Navigation Errors
```dart
void _navigateToAudioDetail(BuildContext context, int audioId) async {
  try {
    // Show loading
    showDialog(context: context, builder: (_) => LoadingDialog());
    
    final result = await repository.getAudioFileById(audioId);
    
    if (!context.mounted) return;
    Navigator.pop(context); // Close loading
    
    result.fold(
      (failure) => _showError(context, failure.message),
      (audioFile) => _navigateToDetailScreen(context, audioFile),
    );
  } catch (e) {
    if (context.mounted) {
      Navigator.pop(context); // Close loading
      _showError(context, 'An unexpected error occurred');
    }
  }
}

void _showError(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
      action: SnackBarAction(
        label: 'Retry',
        textColor: Colors.white,
        onPressed: () {/* Retry logic */},
      ),
    ),
  );
}
```

## Testing Scenarios

1. **Message with audio references only**
   - Verify cards display correctly
   - Test tap navigation
   - Test loading states

2. **Message with note references only**
   - Verify cards display correctly
   - Test tap navigation

3. **Message with both audio and note references**
   - Verify proper layout
   - Test multiple references

4. **Message with suggested questions**
   - Verify chips display
   - Test tap to send question

5. **Empty references**
   - Message without references displays normally
   - No reference cards shown

6. **Error cases**
   - Audio not found (404)
   - Network error during navigation
   - Invalid audio ID

## Performance Considerations

1. **Lazy Loading**: Don't fetch full AudioFile details until user taps
2. **Caching**: Cache recently viewed audio details
3. **Debouncing**: Prevent double-taps on reference cards
4. **Image Loading**: If adding thumbnails, use cached network images
5. **List Performance**: Use `ListView.builder` for long reference lists

## Future Enhancements

1. **Thumbnails**: Show audio waveform or cover image in reference cards
2. **Preview**: Long-press to show quick preview of audio
3. **Batch Actions**: Select multiple references to perform actions
4. **Smart Grouping**: Group references by date or category
5. **Inline Player**: Play audio directly from chat without navigation
