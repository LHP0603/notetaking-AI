# Chatbot Message History API Update Guide

## Overview
This guide describes the updates needed to handle the new enriched message format from the chatbot messages API endpoint. The endpoint now returns fully enriched messages with references and intent data.

## API Changes

### Endpoint
```
GET /chatbot/sessions/{session_id}/messages
```

### Query Parameters
```dart
{
  "limit": int?,   // default: 20
  "offset": int?,  // default: 0
}
```

## New Response Format

### Previous Format (Deprecated)
The old format returned basic fields:
```json
{
  "message_id": "uuid",
  "role": "user",
  "content": "Message text",
  "intent": null,
  "created_at": "timestamp"
}
```

### New Format (Current)

#### User Message
```json
{
  "message_id": "676f1a0a-f863-4e1d-a96b-5cdde9bca68e",
  "role": "user",
  "response": "Tôi muốn biết thêm thông tin về...",
  "intent": "search",
  "created_at": "2025-12-27T02:57:17.672870"
}
```

#### Assistant Message (With References)
```json
{
  "message_id": "d5cd3734-5016-4b38-b201-1e64e80a472e",
  "role": "assistant",
  "response": "Mình tìm thấy 1 bản ghi âm...",
  "intent": "search",
  "audio_references": [
    {
      "audio_id": 30,
      "title": "transcripted audio",
      "duration": 2403.024,
      "created_at": "2025-12-27T01:31:00.676251"
    }
  ],
  "note_references": [
    {
      "note_id": 12,
      "title": "transcripted audio"
    }
  ],
  "created_at": "2025-12-27T02:57:17.673705"
}
```

## Key Changes

### 1. Field Name Change
- **Old**: `content` field contained the message text
- **New**: `response` field contains the message text

### 2. Enriched Assistant Messages
- Assistant messages now include `audio_references` and `note_references` arrays
- References are already populated by the backend
- No need to manually build or fetch references

### 3. Intent Always Present
- Both user and assistant messages now include `intent` field
- For user messages: indicates the detected intent (search, general, etc.)
- For assistant messages: indicates the action type performed

## Updated Data Models

### ChatMessage Entity (Updated)
```dart
import 'package:equatable/equatable.dart';

class ChatMessage extends Equatable {
  final String messageId;
  final String role; // 'user' or 'assistant'
  final String content; // Keep internal field name as 'content' for consistency
  final String? intent;
  final List<AudioReference>? audioReferences;
  final List<NoteReference>? noteReferences;
  final DateTime createdAt;

  const ChatMessage({
    required this.messageId,
    required this.role,
    required this.content,
    this.intent,
    this.audioReferences,
    this.noteReferences,
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
    createdAt,
  ];
}
```

### ChatMessageModel (Updated fromJson)

**IMPORTANT**: The API returns `response` field, but we map it to `content` internally.

```dart
import '../../domain/entities/chat_message.dart';
import 'audio_reference_model.dart';
import 'note_reference_model.dart';

class ChatMessageModel extends ChatMessage {
  const ChatMessageModel({
    required super.messageId,
    required super.role,
    required super.content,
    super.intent,
    super.audioReferences,
    super.noteReferences,
    required super.createdAt,
  });

  /// Parse from message history API response
  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    List<AudioReference>? audioRefs;
    if (json['audio_references'] != null) {
      audioRefs = (json['audio_references'] as List)
          .map((item) => AudioReferenceModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    List<NoteReference>? noteRefs;
    if (json['note_references'] != null) {
      noteRefs = (json['note_references'] as List)
          .map((item) => NoteReferenceModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return ChatMessageModel(
      messageId: json['message_id']?.toString() ?? '',
      role: json['role']?.toString() ?? 'user',
      // Map 'response' field from API to 'content' field in our entity
      content: json['response']?.toString() ?? '',
      intent: json['intent']?.toString(),
      audioReferences: audioRefs,
      noteReferences: noteRefs,
      createdAt: DateTime.parse(json['created_at'].toString()),
    );
  }

  /// Parse from job result (async message sending)
  /// This is used when polling for message completion
  factory ChatMessageModel.fromJobResult(Map<String, dynamic> result) {
    List<AudioReference>? audioRefs;
    if (result['audio_references'] != null) {
      audioRefs = (result['audio_references'] as List)
          .map((item) => AudioReferenceModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    List<NoteReference>? noteRefs;
    if (result['note_references'] != null) {
      noteRefs = (result['note_references'] as List)
          .map((item) => NoteReferenceModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return ChatMessageModel(
      messageId: result['message_id']?.toString() ?? '',
      role: 'assistant',
      content: result['response']?.toString() ?? '',
      intent: result['intent']?.toString(),
      audioReferences: audioRefs,
      noteReferences: noteRefs,
      createdAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message_id': messageId,
      'role': role,
      'response': content, // Map back to 'response' for API
      'intent': intent,
      'audio_references': audioReferences?.map((ref) => {
        'audio_id': ref.audioId,
        'title': ref.title,
        'duration': ref.duration,
        'created_at': ref.createdAt.toIso8601String(),
      }).toList(),
      'note_references': noteReferences?.map((ref) => {
        'note_id': ref.noteId,
        'title': ref.title,
      }).toList(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}
```

### AudioReference & NoteReference Models
These remain the same as defined in `chatbot_references_display.md`. Ensure they are implemented:

```dart
// audio_reference_model.dart
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

// note_reference_model.dart
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

## Updated Remote Data Source

### ChatbotRemoteDataSource Interface
```dart
abstract class ChatbotRemoteDataSource {
  Future<ChatSession> createSession({String? title});
  
  Future<String> sendMessageAsync({
    required String sessionId,
    required String message,
  });
  
  Future<ChatMessage?> pollMessageResult(String jobId);
  
  Future<List<ChatMessage>> getChatHistory({
    required String sessionId,
    int limit = 20,
    int offset = 0,
  });
}
```

### Implementation Update

**Before** (Old parsing):
```dart
Future<List<ChatMessage>> getChatHistory({
  required String sessionId,
  int limit = 20,
  int offset = 0,
}) async {
  final response = await dio.get(
    AppConstants.chatSessionMessages(sessionId),
    queryParameters: {'limit': limit, 'offset': offset},
  );

  final data = _extractData(response, fallbackMessage: 'Failed to load chat history');
  final messages = (data['messages'] as List)
      .map((item) => ChatMessageModel.fromJson({
        'message_id': item['message_id'],
        'role': item['role'],
        'content': item['content'], // OLD FIELD
        'intent': item['intent'],
        'created_at': item['created_at'],
      }))
      .toList();

  return messages;
}
```

**After** (New parsing):
```dart
Future<List<ChatMessage>> getChatHistory({
  required String sessionId,
  int limit = 20,
  int offset = 0,
}) async {
  try {
    final response = await dio.get(
      AppConstants.chatSessionMessages(sessionId),
      queryParameters: {'limit': limit, 'offset': offset},
    );

    final data = _extractData(
      response,
      fallbackMessage: 'Failed to load chat history',
    );

    final messages = (data['messages'] as List)
        .map((item) => ChatMessageModel.fromJson(item as Map<String, dynamic>))
        .toList();

    return messages;
  } on DioException catch (e) {
    throw _handleDioException(
      e,
      fallbackMessage: 'Failed to load chat history',
    );
  }
}
```

**Key changes:**
1. Removed manual field mapping
2. Directly pass the entire item to `fromJson`
3. Let the model handle the `response` → `content` mapping

## Repository Update

The repository layer remains largely the same, but ensure error handling is consistent:

```dart
@override
Future<Either<Failure, List<ChatMessage>>> getChatHistory({
  required String sessionId,
  int limit = 20,
  int offset = 0,
}) async {
  final token = await authLocalDataSource.getAccessToken();
  if (token == null) {
    return const Left(
      UnauthorizedFailure('Please login to view chat history'),
    );
  }

  if (!await networkInfo.isConnected) {
    return const Left(NetworkFailure('No internet connection'));
  }

  try {
    final messages = await remoteDataSource.getChatHistory(
      sessionId: sessionId,
      limit: limit,
      offset: offset,
    );
    return Right(messages);
  } on ServerException catch (e) {
    return Left(ServerFailure(e.message));
  } on NetworkException catch (e) {
    return Left(NetworkFailure(e.message));
  }
}
```

## UI Updates

### Chatbot Screen Changes

#### Loading History
```dart
Future<void> _loadChatHistory() async {
  if (_sessionId == null) return;

  final result = await _repository.getChatHistory(
    sessionId: _sessionId!,
    limit: 20,
    offset: 0,
  );

  if (!mounted) return;

  result.fold(
    (failure) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load history: ${failure.message}')),
      );
    },
    (messages) {
      setState(() {
        _messages = messages.map((msg) => _toFlutterChatMessage(msg)).toList();
      });
    },
  );
}
```

#### Convert to flutter_chat_ui Message
```dart
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

types.Message _toFlutterChatMessage(ChatMessage message) {
  // If message has references, use CustomMessage
  if (message.hasReferences) {
    return types.CustomMessage(
      author: types.User(
        id: message.isUser ? 'user' : 'assistant',
        firstName: message.isUser ? 'You' : 'AI Assistant',
      ),
      createdAt: message.createdAt.millisecondsSinceEpoch,
      id: message.messageId,
      metadata: {
        'chatMessage': message, // Pass entire ChatMessage for custom rendering
      },
    );
  }

  // Regular text message
  return types.TextMessage(
    author: types.User(
      id: message.isUser ? 'user' : 'assistant',
      firstName: message.isUser ? 'You' : 'AI Assistant',
    ),
    createdAt: message.createdAt.millisecondsSinceEpoch,
    id: message.messageId,
    text: message.content,
  );
}
```

#### Custom Message Builder
```dart
Widget _customMessageBuilder(
  types.Message message,
  {required int messageWidth}
) {
  if (message is types.CustomMessage) {
    final chatMessage = message.metadata?['chatMessage'] as ChatMessage?;
    if (chatMessage != null) {
      return ChatMessageBubble(
        message: chatMessage,
        onAudioTap: (audioId) => _navigateToAudioDetail(audioId),
        onNoteTap: (noteId) => _navigateToNoteDetail(noteId),
      );
    }
  }
  
  // Default rendering for other message types
  return const SizedBox.shrink();
}
```

### Display with References

Use the `ChatMessageBubble` widget from `chatbot_references_display.md`:

```dart
class ChatMessageBubble extends StatelessWidget {
  final ChatMessage message;
  final Function(int audioId)? onAudioTap;
  final Function(int noteId)? onNoteTap;

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
            message.content, // Now using 'content' field
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
      ],
    );
  }

  // Implementation from chatbot_references_display.md
  Widget _buildAudioReferences(BuildContext context) {
    // ... (see chatbot_references_display.md)
  }

  Widget _buildNoteReferences(BuildContext context) {
    // ... (see chatbot_references_display.md)
  }
}
```

## Sending Messages (No Changes)

The message sending flow remains the same - only the history loading is affected:

```dart
Future<void> _sendMessage(String text) async {
  // 1. Add user message to UI immediately
  final userMessage = ChatMessage(
    messageId: const Uuid().v4(),
    role: 'user',
    content: text,
    createdAt: DateTime.now(),
  );
  
  setState(() {
    _messages.insert(0, _toFlutterChatMessage(userMessage));
  });

  // 2. Send to backend
  final result = await _repository.sendMessageAsync(
    sessionId: _sessionId!,
    message: text,
  );

  // 3. Poll for result
  result.fold(
    (failure) => _showError(failure.message),
    (jobId) => _pollForResponse(jobId),
  );
}

Future<void> _pollForResponse(String jobId) async {
  // Polling logic remains the same
  // The result will have the new format with references
}
```

## Migration Checklist

### Phase 1: Update Data Models
- [ ] Update `ChatMessage` entity (keep `content` field internally)
- [ ] Update `ChatMessageModel.fromJson()` to map `response` → `content`
- [ ] Ensure `AudioReferenceModel` exists
- [ ] Ensure `NoteReferenceModel` exists
- [ ] Add `fromJobResult()` factory if not exists
- [ ] Add `toJson()` method if needed

### Phase 2: Update Data Source
- [ ] Locate `getChatHistory()` in remote data source
- [ ] Remove manual field mapping
- [ ] Pass entire JSON object to `ChatMessageModel.fromJson()`
- [ ] Test with API to verify parsing works

### Phase 3: Update UI
- [ ] Update `_toFlutterChatMessage()` to detect references
- [ ] Use `CustomMessage` for messages with references
- [ ] Use `TextMessage` for simple messages
- [ ] Implement `_customMessageBuilder()` in Chat widget
- [ ] Integrate `ChatMessageBubble` widget

### Phase 4: Testing
- [ ] Test loading chat history
- [ ] Verify user messages display correctly
- [ ] Verify assistant messages without references display correctly
- [ ] Verify assistant messages with audio references display correctly
- [ ] Verify assistant messages with note references display correctly
- [ ] Verify assistant messages with both types of references display correctly
- [ ] Test tapping on audio references navigates correctly
- [ ] Test tapping on note references navigates correctly
- [ ] Test pagination (if implemented)
- [ ] Test error handling

## Common Issues & Solutions

### Issue 1: "content" field is null
**Cause**: Trying to access old `content` field instead of new `response` field

**Solution**: Update `fromJson()` to map `response` → `content`:
```dart
content: json['response']?.toString() ?? '',
```

### Issue 2: References not displaying
**Cause**: Using `TextMessage` instead of `CustomMessage`

**Solution**: Check `hasReferences` and use appropriate message type:
```dart
if (message.hasReferences) {
  return types.CustomMessage(...);
}
return types.TextMessage(...);
```

### Issue 3: Old messages still using old format
**Cause**: Cached data or old session

**Solution**: 
1. Clear app data/cache
2. Create new chat session
3. Verify API is returning new format

### Issue 4: References not parsing
**Cause**: Missing model classes or incorrect field names

**Solution**: Verify `AudioReferenceModel` and `NoteReferenceModel` exist with correct `fromJson()`:
```dart
AudioReferenceModel.fromJson({
  'audio_id': int,
  'title': String,
  'duration': double,
  'created_at': String,
})
```

## Testing Examples

### Test User Message
```dart
final userMessage = ChatMessage(
  messageId: 'test-1',
  role: 'user',
  content: 'Tìm cho tôi audio về AI',
  intent: 'search',
  createdAt: DateTime.now(),
);
```

### Test Assistant Message with References
```dart
final assistantMessage = ChatMessage(
  messageId: 'test-2',
  role: 'assistant',
  content: 'Mình tìm thấy 2 bản ghi âm phù hợp.',
  intent: 'search',
  audioReferences: [
    AudioReference(
      audioId: 30,
      title: 'AI and Machine Learning',
      duration: 1234.5,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ],
  noteReferences: [
    NoteReference(
      noteId: 12,
      title: 'AI Summary',
    ),
  ],
  createdAt: DateTime.now(),
);
```

### Test JSON Parsing
```dart
void testParsing() {
  final json = {
    "message_id": "test-id",
    "role": "assistant",
    "response": "Test message",
    "intent": "search",
    "audio_references": [
      {
        "audio_id": 30,
        "title": "Test Audio",
        "duration": 100.0,
        "created_at": "2025-12-27T10:00:00Z"
      }
    ],
    "note_references": [],
    "created_at": "2025-12-27T10:00:00Z"
  };

  final message = ChatMessageModel.fromJson(json);
  
  assert(message.content == "Test message");
  assert(message.audioReferences?.length == 1);
  assert(message.audioReferences?.first.audioId == 30);
}
```

## Integration with Existing Documentation

This guide complements:
1. **chatbot_integration.md** - Initial setup and session management
2. **chatbot_references_display.md** - Reference card UI components

Make sure to implement both guides together for complete functionality.

## Summary of Changes

| Aspect | Old | New |
|--------|-----|-----|
| Field name | `content` | `response` (API) → `content` (internal) |
| User messages | Basic fields only | Includes intent |
| Assistant messages | Basic fields only | Includes references and intent |
| Parsing | Manual field mapping | Direct JSON parsing |
| UI rendering | Always TextMessage | TextMessage or CustomMessage based on references |
| References | Not supported | Audio and note references with navigation |

## Next Steps

After implementing these changes:
1. Test with real API data
2. Verify all message types display correctly
3. Test navigation from references
4. Implement caching if needed
5. Add error handling for malformed messages
6. Consider adding loading states for references
7. Add analytics to track reference clicks
