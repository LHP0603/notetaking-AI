# Chatbot Integration Implementation Guide

## Overview
This guide describes the implementation of chatbot functionality in the Voicely app, including session management, message sending, and chat history retrieval.

## Architecture

### Components Needed
1. **Data Layer**
   - `ChatbotRemoteDataSource` - API communication
   - `ChatbotRepository` - Business logic and error handling
   
2. **Domain Layer**
   - `ChatSession` entity
   - `ChatMessage` entity
   - Use cases (optional, can be integrated directly into repository)

3. **Presentation Layer**
   - Chat screen/modal UI
   - BLoC/Cubit for state management
   - Message list widget
   - Input widget

## Implementation Flow

### 1. Create/Resume Chat Session

#### When to Create Session
- User opens chat modal for the first time
- No active session exists in local storage
- User explicitly starts a new conversation

#### Endpoint
```
POST /chatbot/sessions
```

#### Request Payload
```json
{
  "title": "Chat Session"  // Optional, can be null or omitted
}
```

#### Response
```json
{
  "success": true,
  "message": "Session created successfully",
  "data": {
    "session_id": "uuid-string",
    "title": "Chat Session",
    "total_messages": 0,
    "is_active": true,
    "created_at": "2025-12-26T10:30:00Z",
    "updated_at": "2025-12-26T10:30:00Z"
  }
}
```

#### Implementation Tasks
- [ ] Add endpoint constant to `AppConstants`
- [ ] Create `ChatSession` entity class
- [ ] Create `ChatSessionModel` with `fromJson` factory
- [ ] Add `createChatSession()` method to remote data source
- [ ] Add `createChatSession()` method to repository with error handling
- [ ] Save `session_id` to local storage (SharedPreferences or secure storage)
- [ ] Add session creation logic to chat screen initialization

### 2. Send Messages (Asynchronous Approach - Recommended)

#### Why Async?
- Better UX for long-running AI responses
- Prevents timeout errors
- Allows UI to show loading states
- Can handle network interruptions gracefully

#### Endpoint
```
POST /chatbot/sessions/{session_id}/messages-async
```

#### Request Payload
```json
{
  "message": "User's message text here"
}
```

#### Response
```json
{
  "success": true,
  "message": "Task queued successfully",
  "data": {
    "job_id": "uuid",
    "status": "queued"
  }
}
```

#### Poll for Result
```
GET /tasks/jobs/{job_id}
```

#### Poll Response (In Progress)
```json
{
  "success": true,
  "data": {
    "job_id": "uuid",
    "status": "processing",
    "result": null
  }
}
```

#### Poll Response (Completed)
```json
{
  "success": true,
  "data": {
    "job_id": "uuid",
    "status": "completed",
    "result": {
      "message_id": "uuid",
      "role": "assistant",
      "content": "AI response text here",
      "intent": "search_notes",
      "created_at": "2025-12-26T10:31:00Z"
    }
  }
}
```

#### Implementation Tasks
- [ ] Add `sendMessageAsync()` to remote data source
- [ ] Add `pollJobStatus()` to remote data source (reuse existing task polling if available)
- [ ] Create `ChatMessage` entity with fields: `messageId`, `role`, `content`, `intent`, `createdAt`
- [ ] Create `ChatMessageModel` with `fromJson` factory
- [ ] Add `sendMessage()` to repository that:
  - Calls async endpoint
  - Starts polling job status
  - Returns stream or future of message
- [ ] Add polling logic to chat screen/bloc
- [ ] Display user message immediately (optimistic UI)
- [ ] Show loading indicator for AI response
- [ ] Update UI when AI response arrives

### 3. Load Chat History

#### When to Load
- User opens existing chat session
- User scrolls to top (pagination)
- App resumes from background

#### Endpoint
```
GET /chatbot/sessions/{session_id}/messages?limit=20&offset=0
```

#### Query Parameters
- `limit`: Number of messages to load (default: 20)
- `offset`: Skip first N messages for pagination (default: 0)

#### Response
```json
{
  "success": true,
  "message": "Session history retrieved",
  "data": {
    "session_id": "uuid",
    "messages": [
      {
        "message_id": "uuid",
        "role": "user",
        "content": "Previous user message",
        "intent": null,
        "created_at": "2025-12-26T09:00:00Z"
      },
      {
        "message_id": "uuid",
        "role": "assistant",
        "content": "Previous AI response",
        "intent": "search_notes",
        "created_at": "2025-12-26T09:00:05Z"
      }
    ],
    "total": 10,
    "limit": 20,
    "offset": 0
  }
}
```

#### Implementation Tasks
- [ ] Add `getChatHistory()` to remote data source
- [ ] Add pagination support in repository
- [ ] Load initial messages when opening chat
- [ ] Implement infinite scroll for older messages
- [ ] Cache messages locally for offline viewing (optional)

## Data Models

### ChatSession Entity
```dart
class ChatSession extends Equatable {
  final String sessionId;
  final String? title;
  final int totalMessages;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ChatSession({
    required this.sessionId,
    this.title,
    required this.totalMessages,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
    sessionId,
    title,
    totalMessages,
    isActive,
    createdAt,
    updatedAt,
  ];
}
```

### ChatMessage Entity
```dart
class ChatMessage extends Equatable {
  final String messageId;
  final String role; // 'user' or 'assistant'
  final String content;
  final String? intent;
  final DateTime createdAt;

  const ChatMessage({
    required this.messageId,
    required this.role,
    required this.content,
    this.intent,
    required this.createdAt,
  });

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';

  @override
  List<Object?> get props => [
    messageId,
    role,
    content,
    intent,
    createdAt,
  ];
}
```

## State Management

### Chat State (BLoC/Cubit)
```dart
class ChatState extends Equatable {
  final ChatSession? session;
  final List<ChatMessage> messages;
  final bool isLoading;
  final bool isSending;
  final String? error;
  final bool hasMore; // For pagination

  const ChatState({
    this.session,
    this.messages = const [],
    this.isLoading = false,
    this.isSending = false,
    this.error,
    this.hasMore = true,
  });

  // copyWith method...
}
```

### Events/Methods
- `initializeChat()` - Create or load session
- `sendMessage(String message)` - Send user message
- `loadMoreMessages()` - Pagination
- `refreshSession()` - Reload chat

## UI Flow

### 1. Opening Chat Modal
```
1. Check if session_id exists in local storage
2. If exists:
   - Load session details
   - Load recent messages (limit: 20, offset: 0)
3. If not exists:
   - Call POST /chatbot/sessions
   - Save session_id
   - Show empty chat UI
```

### 2. Sending Message
```
1. User types message and hits send
2. Add user message to UI immediately (optimistic update)
3. Call POST /chatbot/sessions/{session_id}/messages-async
4. Get job_id from response
5. Show loading indicator for AI response
6. Poll GET /tasks/jobs/{job_id} every 2-3 seconds
7. When status = "completed":
   - Add AI message to UI
   - Stop polling
8. Handle errors gracefully
```

### 3. Loading More Messages
```
1. User scrolls to top of message list
2. Calculate offset (current message count)
3. Call GET /chatbot/sessions/{session_id}/messages?limit=20&offset={offset}
4. Prepend messages to list
5. If messages.length < limit, set hasMore = false
```

## Error Handling

### Common Errors
- **No session**: Create new session automatically
- **Network timeout**: Retry logic with exponential backoff
- **Invalid session_id**: Clear local storage, create new session
- **Job polling timeout**: Show error, allow retry

### Error Messages
- "Failed to connect to chatbot. Please try again."
- "Session expired. Starting new conversation..."
- "Message sending failed. Retry?"

## Best Practices

1. **Session Management**
   - Store session_id in secure storage
   - Validate session on app resume
   - Clear session on logout

2. **Message Handling**
   - Use optimistic UI updates for user messages
   - Implement retry logic for failed messages
   - Show clear loading states

3. **Polling**
   - Use reasonable polling intervals (2-3 seconds)
   - Set maximum retry count (e.g., 30 attempts = 90 seconds)
   - Cancel polling when user leaves chat

4. **Performance**
   - Implement message pagination
   - Cache messages locally
   - Lazy load message history

5. **UX**
   - Auto-scroll to latest message
   - Show typing indicators
   - Display timestamps
   - Group messages by date

## Integration with flutter_chat_ui

Since the project uses `flutter_chat_ui` package, leverage its features:

```dart
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';

// Convert ChatMessage to flutter_chat_types.Message
types.Message _toFlutterChatMessage(ChatMessage message) {
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

## Testing Checklist

- [ ] Create new session successfully
- [ ] Send message and receive response
- [ ] Load message history with pagination
- [ ] Handle network errors gracefully
- [ ] Handle session expiration
- [ ] Polling timeout handling
- [ ] Offline mode behavior
- [ ] Multiple rapid messages handling

## Constants to Add

```dart
// In AppConstants
static const String chatSessionsEndpoint = '/chatbot/sessions';
static String chatSessionMessagesAsync(String sessionId) => 
  '/chatbot/sessions/$sessionId/messages-async';
static String chatSessionMessages(String sessionId) => 
  '/chatbot/sessions/$sessionId/messages';
static String jobStatus(String jobId) => '/tasks/jobs/$jobId';

// Polling settings
static const Duration chatPollingInterval = Duration(seconds: 3);
static const int maxChatPollingRetries = 30; // 90 seconds max
```

## Implementation Order

1. **Phase 1: Basic Structure**
   - Create entity classes
   - Create model classes
   - Add constants

2. **Phase 2: Data Layer**
   - Implement remote data source methods
   - Implement repository with error handling
   - Add session storage logic

3. **Phase 3: State Management**
   - Create BLoC/Cubit
   - Define states and events
   - Implement business logic

4. **Phase 4: UI**
   - Create chat screen layout
   - Integrate flutter_chat_ui
   - Add message input widget
   - Implement message list with pagination

5. **Phase 5: Polish**
   - Add loading states
   - Error handling UI
   - Retry mechanisms
   - Offline support
