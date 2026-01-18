# AI Chatbot UI Implementation Guide

## Overview
This document provides implementation instructions for creating a modern chat interface with an AI chatbot. The chat UI appears as a full-screen modal bottom sheet with a floating action button trigger on the main screen.

## Feature Requirements

### 1. Floating Action Button on Main Screen

A floating button that:
- Is visible on the main screen
- Has an animation effect (optional but recommended)
- Opens the chat interface when tapped
- Uses a chat or AI icon

### 2. Chat Modal Bottom Sheet

A chat interface that:
- Appears as a `showModalBottomSheet` (modern popup feel)
- Covers the entire screen
- Can be dismissed by swiping down
- Uses `flutter_chat_ui` library for beautiful chat UI
- Shows typing indicator when chatbot is responding

## Dependencies

Add to `pubspec.yaml`:

```yaml
dependencies:
  flutter_chat_ui: ^1.6.12
  flutter_chat_types: ^3.6.2
  uuid: ^4.0.0 # For generating unique message IDs
```

Run:
```bash
flutter pub get
```

## Implementation

### 1. Main Screen with Floating Button

#### Add Floating Action Button

**File**: `lib/features/main/presentation/pages/main_screen.dart` (or your main screen)

```dart
import 'package:flutter/material.dart';
import '../../../chatbot/presentation/pages/chatbot_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    // Optional: Add pulse animation to FAB
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _openChatbot() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allow full-screen height
      backgroundColor: Colors.transparent, // Transparent to show custom design
      builder: (context) => const ChatbotScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voicely'),
      ),
      body: YourMainContent(),
      floatingActionButton: ScaleTransition(
        scale: _scaleAnimation,
        child: FloatingActionButton.extended(
          onPressed: _openChatbot,
          icon: const Icon(Icons.chat_bubble_outline),
          label: const Text('AI Assistant'),
          backgroundColor: const Color(0xFF3B82F6),
          heroTag: 'chatbot_fab', // Unique tag for hero animation
        ),
      ),
    );
  }
}
```

**Alternative Simple FAB** (without animation):
```dart
floatingActionButton: FloatingActionButton(
  onPressed: _openChatbot,
  child: const Icon(Icons.smart_toy), // AI robot icon
  backgroundColor: const Color(0xFF3B82F6),
  tooltip: 'Chat with AI Assistant',
)
```

### 2. Chatbot Screen as Modal Bottom Sheet

Create a new file for the chatbot screen:

**File**: `lib/features/chatbot/presentation/pages/chatbot_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:uuid/uuid.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({Key? key}) : super(key: key);

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final List<types.Message> _messages = [];
  final _user = const types.User(id: 'user');
  final _bot = const types.User(
    id: 'bot',
    firstName: 'AI',
    lastName: 'Assistant',
  );
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _addWelcomeMessage();
  }

  void _addWelcomeMessage() {
    final welcomeMessage = types.TextMessage(
      author: _bot,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: const Uuid().v4(),
      text: 'Hello! I\'m your AI assistant. How can I help you today?',
    );
    
    setState(() {
      _messages.insert(0, welcomeMessage);
    });
  }

  void _handleSendPressed(types.PartialText message) {
    final textMessage = types.TextMessage(
      author: _user,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: const Uuid().v4(),
      text: message.text,
    );

    _addMessage(textMessage);
    _simulateBotResponse(message.text);
  }

  void _addMessage(types.Message message) {
    setState(() {
      _messages.insert(0, message);
    });
  }

  Future<void> _simulateBotResponse(String userMessage) async {
    // Show typing indicator
    setState(() {
      _isTyping = true;
    });

    // TODO: Replace with actual API call to chatbot backend
    await Future.delayed(const Duration(seconds: 2));

    // Simulate bot response
    final botResponse = types.TextMessage(
      author: _bot,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: const Uuid().v4(),
      text: 'I received your message: "$userMessage". This is a simulated response. In production, this will be replaced with an actual AI chatbot API call.',
    );

    setState(() {
      _isTyping = false;
      _messages.insert(0, botResponse);
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      height: screenHeight - topPadding + 16,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF3B82F6),
                  child: const Icon(Icons.smart_toy, color: Colors.white),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Assistant',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Always here to help',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          
          const Divider(height: 1),
          
          // Chat UI
          Expanded(
            child: Chat(
              messages: _messages,
              onSendPressed: _handleSendPressed,
              user: _user,
              showUserAvatars: true,
              showUserNames: true,
              isTyping: _isTyping,
              theme: DefaultChatTheme(
                primaryColor: const Color(0xFF3B82F6),
                secondaryColor: const Color(0xFFF3F4F6),
                backgroundColor: Colors.white,
                inputBackgroundColor: const Color(0xFFF3F4F6),
                inputTextColor: Colors.black87,
                inputBorderRadius: BorderRadius.circular(24),
                messageBorderRadius: 20,
                userAvatarNameColors: [const Color(0xFF3B82F6)],
              ),
              // Customize typing indicator
              typingIndicatorOptions: const TypingIndicatorOptions(
                typingMode: TypingIndicatorMode.name,
                typingUsers: [
                  types.User(
                    id: 'bot',
                    firstName: 'AI Assistant',
                  ),
                ],
              ),
              // Customize input
              inputOptions: const InputOptions(
                sendButtonVisibilityMode: SendButtonVisibilityMode.always,
              ),
              // Avatar builder for bot messages
              avatarBuilder: (author) {
                if (author.id == 'bot') {
                  return CircleAvatar(
                    backgroundColor: const Color(0xFF3B82F6),
                    radius: 16,
                    child: const Icon(
                      Icons.smart_toy,
                      color: Colors.white,
                      size: 18,
                    ),
                  );
                }
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }
}
```

### 3. Enhanced Floating Button with Advanced Animation

For a more sophisticated floating button with multiple animation effects:

```dart
class AnimatedChatFAB extends StatefulWidget {
  final VoidCallback onPressed;

  const AnimatedChatFAB({
    Key? key,
    required this.onPressed,
  }) : super(key: key);

  @override
  State<AnimatedChatFAB> createState() => _AnimatedChatFABState();
}

class _AnimatedChatFABState extends State<AnimatedChatFAB>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _bounceController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();

    // Pulse animation
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    // Bounce animation on tap
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _bounceAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(
        parent: _bounceController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    await _bounceController.forward();
    await _bounceController.reverse();
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: ScaleTransition(
        scale: _bounceAnimation,
        child: FloatingActionButton.extended(
          onPressed: _handleTap,
          icon: const Icon(Icons.chat_bubble_outline),
          label: const Text('AI Chat'),
          backgroundColor: const Color(0xFF3B82F6),
          elevation: 6,
          heroTag: 'chatbot_fab',
        ),
      ),
    );
  }
}
```

Usage:
```dart
floatingActionButton: AnimatedChatFAB(
  onPressed: _openChatbot,
)
```

### 4. Custom Theme Configuration

Create a custom theme for the chat UI:

```dart
class ChatbotTheme {
  static const primaryColor = Color(0xFF3B82F6);
  static const secondaryColor = Color(0xFFF3F4F6);
  static const backgroundColor = Colors.white;

  static DefaultChatTheme get theme => DefaultChatTheme(
        primaryColor: primaryColor,
        secondaryColor: secondaryColor,
        backgroundColor: backgroundColor,
        inputBackgroundColor: secondaryColor,
        inputTextColor: Colors.black87,
        inputBorderRadius: BorderRadius.circular(24),
        messageBorderRadius: 20,
        userAvatarNameColors: [primaryColor],
        receivedMessageBodyTextStyle: const TextStyle(
          color: Colors.black87,
          fontSize: 16,
          height: 1.5,
        ),
        sentMessageBodyTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          height: 1.5,
        ),
        inputTextStyle: const TextStyle(
          fontSize: 16,
          color: Colors.black87,
        ),
      );

  static TypingIndicatorOptions get typingIndicatorOptions =>
      const TypingIndicatorOptions(
        typingMode: TypingIndicatorMode.name,
        typingUsers: [
          types.User(
            id: 'bot',
            firstName: 'AI Assistant',
          ),
        ],
      );
}
```

Usage:
```dart
Chat(
  // ... other properties
  theme: ChatbotTheme.theme,
  typingIndicatorOptions: ChatbotTheme.typingIndicatorOptions,
)
```

### 5. Advanced Modal Bottom Sheet Configuration

For better user experience and customization:

```dart
void _openChatbot() {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    isDismissible: true, // Can dismiss by tapping outside
    enableDrag: true, // Can swipe down to dismiss
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black54, // Semi-transparent overlay
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(20),
        topRight: Radius.circular(20),
      ),
    ),
    transitionAnimationController: AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: Navigator.of(context),
    ),
    builder: (context) => const ChatbotScreen(),
  ).then((_) {
    // Optional: Handle when modal is dismissed
    print('Chat closed');
  });
}
```

### 6. Message Types Examples

flutter_chat_ui supports various message types:

#### Text Message
```dart
final textMessage = types.TextMessage(
  author: _bot,
  createdAt: DateTime.now().millisecondsSinceEpoch,
  id: const Uuid().v4(),
  text: 'Hello! How can I help you?',
);
```

#### Image Message
```dart
final imageMessage = types.ImageMessage(
  author: _bot,
  createdAt: DateTime.now().millisecondsSinceEpoch,
  id: const Uuid().v4(),
  name: 'image.jpg',
  size: 1024,
  uri: 'https://example.com/image.jpg',
);
```

#### File Message
```dart
final fileMessage = types.FileMessage(
  author: _bot,
  createdAt: DateTime.now().millisecondsSinceEpoch,
  id: const Uuid().v4(),
  name: 'document.pdf',
  size: 2048,
  uri: 'https://example.com/document.pdf',
);
```

### 7. Typing Indicator Control

The typing indicator is controlled by the `_isTyping` boolean:

```dart
// Show typing indicator
setState(() {
  _isTyping = true;
});

// Make API call
final response = await chatbotApi.sendMessage(message);

// Hide typing indicator and show response
setState(() {
  _isTyping = false;
  _messages.insert(0, response);
});
```

### 8. Integration with API (Placeholder)

Replace the simulated response with actual API call:

```dart
Future<void> _sendMessageToBot(String userMessage) async {
  setState(() {
    _isTyping = true;
  });

  try {
    // TODO: Replace with actual API call
    final response = await context
        .read<ChatbotBloc>()
        .repository
        .sendMessage(userMessage);

    final botMessage = types.TextMessage(
      author: _bot,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: const Uuid().v4(),
      text: response.text,
    );

    setState(() {
      _messages.insert(0, botMessage);
    });
  } catch (e) {
    final errorMessage = types.TextMessage(
      author: _bot,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: const Uuid().v4(),
      text: 'Sorry, I encountered an error. Please try again.',
    );

    setState(() {
      _messages.insert(0, errorMessage);
    });
  } finally {
    setState(() {
      _isTyping = false;
    });
  }
}
```

## File Structure

```
lib/
├── features/
│   ├── chatbot/
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   └── chatbot_remote_data_source.dart
│   │   │   ├── models/
│   │   │   │   └── chat_message_model.dart
│   │   │   └── repositories/
│   │   │       └── chatbot_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── chat_message.dart
│   │   │   ├── repositories/
│   │   │   │   └── chatbot_repository.dart
│   │   │   └── usecases/
│   │   │       └── send_message.dart
│   │   └── presentation/
│   │       ├── bloc/
│   │       │   └── chatbot_bloc.dart
│   │       ├── pages/
│   │       │   └── chatbot_screen.dart
│   │       └── widgets/
│   │           ├── animated_chat_fab.dart
│   │           └── chatbot_theme.dart
│   └── main/
│       └── presentation/
│           └── pages/
│               └── main_screen.dart
```

## Implementation Checklist

### UI Components
- [ ] Add flutter_chat_ui and dependencies to pubspec.yaml
- [ ] Create ChatbotScreen widget as modal bottom sheet
- [ ] Add floating action button to main screen
- [ ] Implement drag handle for modal
- [ ] Add custom header with avatar and close button
- [ ] Configure chat theme

### Chat Functionality
- [ ] Initialize user and bot objects
- [ ] Add welcome message on screen open
- [ ] Implement _handleSendPressed for user messages
- [ ] Show typing indicator when _isTyping = true
- [ ] Add simulated bot response (placeholder)
- [ ] Handle message list updates

### Animation
- [ ] Add pulse animation to FAB (optional)
- [ ] Add bounce animation on FAB tap (optional)
- [ ] Configure modal transition animation
- [ ] Test swipe-to-dismiss gesture

### Integration (Future)
- [ ] Create chatbot API data source
- [ ] Create chatbot repository
- [ ] Create send message use case
- [ ] Replace simulated response with API call
- [ ] Handle API errors gracefully

## Customization Options

### 1. Change FAB Position
```dart
floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
// or
floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
```

### 2. Custom Modal Height
```dart
Container(
  height: screenHeight * 0.85, // 85% of screen height
  // ... rest of the widget
)
```

### 3. Disable Swipe-to-Dismiss
```dart
showModalBottomSheet(
  enableDrag: false, // Disable swipe down
  isDismissible: false, // Disable tap outside
  // ... rest
)
```

### 4. Custom Typing Indicator Text
```dart
typingIndicatorOptions: const TypingIndicatorOptions(
  typingMode: TypingIndicatorMode.name,
  customTypingIndicatorText: 'AI is thinking...',
)
```

## Testing Checklist

- [ ] FAB appears on main screen
- [ ] FAB animation works smoothly
- [ ] Clicking FAB opens modal bottom sheet
- [ ] Modal covers entire screen
- [ ] Drag handle is visible and functional
- [ ] Swipe down to dismiss works
- [ ] Tap outside to dismiss works (if enabled)
- [ ] Close button dismisses modal
- [ ] Welcome message appears on open
- [ ] User can send messages
- [ ] Messages appear in correct order
- [ ] Typing indicator shows when bot is responding
- [ ] Typing indicator hides after response
- [ ] Bot responses appear correctly
- [ ] Chat UI theme is applied correctly
- [ ] Avatar images display properly
- [ ] Input field is functional
- [ ] Send button visibility works

## Notes

- The modal bottom sheet provides a modern "popup" experience without navigating to a new screen
- `isScrollControlled: true` allows the modal to take full screen height
- The drag handle provides visual affordance for swipe-to-dismiss gesture
- `_isTyping` controls the typing indicator display
- Use `flutter_chat_types` for message type definitions
- The UUID package is used to generate unique message IDs
- Custom theme can be adjusted to match app branding
- Consider persisting chat history using local storage
- Consider adding features like voice input, file sharing, etc.
- The chat UI is fully responsive and handles keyboard appearance
