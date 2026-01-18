import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:uuid/uuid.dart';
import '../../../../injection_container/injection_container.dart';
import '../../../audio_manager/domain/entities/note.dart';
import '../../../audio_manager/domain/repositories/audio_manager_repository.dart';
import '../../../audio_manager/presentation/pages/audio_detail_screen.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/audio_reference.dart';
import '../../domain/entities/note_reference.dart';
import '../../domain/repositories/chatbot_repository.dart';
import '../widgets/chat_message_bubble.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final ChatbotRepository _repository = sl<ChatbotRepository>();
  final AudioManagerRepository _audioRepository = sl<AudioManagerRepository>();
  final List<types.Message> _messages = [];
  final Set<String> _messageIds = <String>{};
  final types.User _user = const types.User(id: 'user');
  final types.User _bot = const types.User(
    id: 'bot',
    firstName: 'AI',
    lastName: 'Assistant',
  );
  final Uuid _uuid = Uuid();
  static const int _historyPageSize = 20;

  String? _sessionId;
  int _pendingResponses = 0;
  bool _isInitializing = false;
  bool _isLoadingMore = false;
  bool _hasMoreHistory = true;
  int _historyOffset = 0;

  bool get _isTyping => _pendingResponses > 0;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    setState(() {
      _isInitializing = true;
    });
    _resetHistoryState();

    final cachedResult = await _repository.getCachedSessionId();
    if (!mounted) {
      return;
    }

    String? cachedSessionId;
    cachedResult.fold(
      (_) {},
      (sessionId) {
        if (sessionId != null && sessionId.isNotEmpty) {
          cachedSessionId = sessionId;
        }
      },
    );

    if (cachedSessionId != null) {
      final historyResult = await _repository.getChatHistory(
        sessionId: cachedSessionId!,
        limit: _historyPageSize,
        offset: 0,
      );
      if (!mounted) {
        return;
      }

      final historyLoaded = historyResult.fold(
        (_) => false,
        (messages) {
          _sessionId = cachedSessionId;
          _setHistoryMessages(messages);
          return true;
        },
      );

      if (!historyLoaded) {
        await _createNewSession();
      }
    } else {
      await _createNewSession();
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isInitializing = false;
    });
  }

  Future<void> _createNewSession() async {
    final result = await _repository.createChatSession();
    if (!mounted) {
      return;
    }

    result.fold(
      (failure) => _addErrorMessage(failure.message),
      (session) {
        setState(() {
          _sessionId = session.sessionId;
          _messages.clear();
        });
        _resetHistoryState(hasMore: false);
        _addWelcomeMessage();
      },
    );
  }

  void _addWelcomeMessage() {
    if (_messages.isNotEmpty) {
      return;
    }

    final welcomeMessage = _buildUserTextMessage(
      author: _bot,
      text: 'Hello! I\'m your AI assistant. How can I help you today?',
    );

    _addMessage(welcomeMessage);
  }

  void _handleSendPressed(types.PartialText message) {
    final trimmed = message.text.trim();
    if (trimmed.isEmpty) {
      return;
    }

    if (_sessionId == null) {
      _addErrorMessage('Chat is still loading. Please try again.');
      return;
    }

    final textMessage = _buildUserTextMessage(
      author: _user,
      text: trimmed,
    );

    _addMessage(textMessage);
    _incrementTyping();
    _sendMessage(_sessionId!, trimmed);
  }

  Future<void> _sendMessage(String sessionId, String message) async {
    if (_sessionId == null) {
      _decrementTyping();
      return;
    }

    final result = await _repository.sendMessage(
      sessionId: sessionId,
      message: message,
    );

    if (!mounted) {
      return;
    }

    if (sessionId != _sessionId) {
      _decrementTyping();
      return;
    }

    result.fold(
      (failure) => _addErrorMessage(failure.message),
      (chatMessage) => _addMessage(_toFlutterChatMessage(chatMessage)),
    );

    _decrementTyping();
  }

  void _incrementTyping() {
    if (!mounted) {
      return;
    }
    setState(() {
      _pendingResponses += 1;
    });
  }

  void _decrementTyping() {
    if (!mounted) {
      return;
    }
    setState(() {
      if (_pendingResponses > 0) {
        _pendingResponses -= 1;
      }
    });
  }

  void _setHistoryMessages(List<ChatMessage> messages) {
    final sorted = List<ChatMessage>.from(messages)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final mapped = sorted.map(_toFlutterChatMessage).toList();

    _messageIds
      ..clear()
      ..addAll(mapped.map((message) => message.id));
    _historyOffset = messages.length;
    _hasMoreHistory = messages.length == _historyPageSize;

    setState(() {
      _messages
        ..clear()
        ..addAll(mapped);
    });

    if (_messages.isEmpty) {
      _addWelcomeMessage();
    }
  }

  Future<void> _loadMoreHistory() async {
    final sessionId = _sessionId;
    if (sessionId == null ||
        _isInitializing ||
        _isLoadingMore ||
        !_hasMoreHistory) {
      return;
    }

    setState(() {
      _isLoadingMore = true;
    });

    final result = await _repository.getChatHistory(
      sessionId: sessionId,
      limit: _historyPageSize,
      offset: _historyOffset,
    );

    if (!mounted) {
      return;
    }

    var hasMore = _hasMoreHistory;
    var nextOffset = _historyOffset;

    result.fold(
      (failure) => _addErrorMessage(failure.message),
      (messages) {
        if (messages.isEmpty) {
          hasMore = false;
          return;
        }

        _mergeHistoryMessages(messages);
        nextOffset += messages.length;
        if (messages.length < _historyPageSize) {
          hasMore = false;
        }
      },
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isLoadingMore = false;
      _historyOffset = nextOffset;
      _hasMoreHistory = hasMore;
    });
  }

  void _mergeHistoryMessages(List<ChatMessage> messages) {
    final additions = <types.Message>[];

    for (final message in messages) {
      if (_messageIds.contains(message.messageId)) {
        continue;
      }
      final mapped = _toFlutterChatMessage(message);
      _messageIds.add(mapped.id);
      additions.add(mapped);
    }

    if (additions.isEmpty) {
      return;
    }

    final merged = [..._messages, ...additions];
    merged.sort(
      (a, b) => _messageTimestamp(b).compareTo(_messageTimestamp(a)),
    );

    setState(() {
      _messages
        ..clear()
        ..addAll(merged);
    });
  }

  void _resetHistoryState({bool hasMore = true}) {
    _historyOffset = 0;
    _isLoadingMore = false;
    _hasMoreHistory = hasMore;
    _messageIds.clear();
  }

  void _addMessage(types.Message message) {
    if (!mounted) {
      return;
    }
    _messageIds.add(message.id);
    setState(() {
      _messages.insert(0, message);
    });
  }

  void _addErrorMessage(String message) {
    final errorMessage = _buildUserTextMessage(
      author: _bot,
      text: message,
    );

    _addMessage(errorMessage);
  }

  int _messageTimestamp(types.Message message) {
    return message.createdAt ?? 0;
  }

  types.Message _toFlutterChatMessage(ChatMessage message) {
    final author = message.isUser ? _user : _bot;
    if (message.isAssistant &&
        (message.hasReferences || message.hasSuggestions)) {
      return types.CustomMessage(
        author: author,
        createdAt: message.createdAt.millisecondsSinceEpoch,
        id: message.messageId,
        metadata: {'chatMessage': message},
      );
    }

    return types.TextMessage(
      author: author,
      createdAt: message.createdAt.millisecondsSinceEpoch,
      id: message.messageId,
      text: message.content,
    );
  }

  types.TextMessage _buildUserTextMessage({
    required types.User author,
    required String text,
  }) {
    return types.TextMessage(
      author: author,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: _uuid.v4(),
      text: text,
    );
  }

  Widget _customMessageBuilder(
    types.CustomMessage message, {
    required int messageWidth,
  }) {
    final metadata = message.metadata ?? <String, dynamic>{};
    final chatMessage = metadata['chatMessage'];
    if (chatMessage is! ChatMessage) {
      return const SizedBox.shrink();
    }

    return ChatMessageBubble(
      message: chatMessage,
      maxWidth: messageWidth.toDouble(),
      onAudioTap: _handleAudioReferenceTap,
      onNoteTap: _handleNoteReferenceTap,
      onSuggestedQuestionTap: _handleSuggestedQuestion,
    );
  }

  void _handleSuggestedQuestion(String question) {
    _handleSendPressed(types.PartialText(text: question));
  }

  Future<void> _handleAudioReferenceTap(AudioReference audio) async {
    await _navigateToAudioDetail(audio.audioId);
  }

  Future<void> _handleNoteReferenceTap(NoteReference note) async {
    await _navigateToNoteDetail(note.noteId);
  }

  Future<void> _navigateToAudioDetail(int audioId) async {
    await _runWithLoading(() async {
      final result = await _audioRepository.getAudioFileById(audioId);
      if (!mounted) {
        return;
      }

      result.fold(
        (failure) => _showError('Failed to load audio: ${failure.message}'),
        (audioFile) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => AudioDetailScreen(audioFile: audioFile),
            ),
          );
        },
      );
    });
  }

  Future<void> _navigateToNoteDetail(int noteId) async {
    await _runWithLoading(() async {
      final noteResult = await _audioRepository.getNoteById(noteId);
      if (!mounted) {
        return;
      }

      Note? note;
      noteResult.fold(
        (failure) => _showError('Failed to load note: ${failure.message}'),
        (loadedNote) => note = loadedNote,
      );

      if (note == null) {
        return;
      }

      final audioResult =
          await _audioRepository.getAudioFileById(note!.audioFileId);
      if (!mounted) {
        return;
      }

      audioResult.fold(
        (failure) => _showError('Failed to load audio: ${failure.message}'),
        (audioFile) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => AudioDetailScreen(audioFile: audioFile),
            ),
          );
        },
      );
    });
  }

  Future<void> _runWithLoading(Future<void> Function() action) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      await action();
    } finally {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _startNewChat() async {
    setState(() {
      _isInitializing = true;
      _pendingResponses = 0;
      _messages.clear();
      _sessionId = null;
    });
    _resetHistoryState(hasMore: false);

    final clearResult = await _repository.clearCachedSessionId();
    if (!mounted) {
      return;
    }

    clearResult.fold(
      (failure) => _addErrorMessage(failure.message),
      (_) {},
    );

    await _createNewSession();
    if (!mounted) {
      return;
    }

    setState(() {
      _isInitializing = false;
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
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Color(0xFF3B82F6),
                  child: Icon(Icons.smart_toy, color: Colors.white),
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
                  icon: const Icon(Icons.add_comment_outlined),
                  tooltip: 'New chat',
                  onPressed: _isInitializing ? null : _startNewChat,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: Stack(
              children: [
                Chat(
                  messages: _messages,
                  onSendPressed: _handleSendPressed,
                  user: _user,
                  showUserAvatars: true,
                  showUserNames: true,
                  isLastPage: !_hasMoreHistory,
                  onEndReached: _loadMoreHistory,
                  onEndReachedThreshold: 0.2,
                  customMessageBuilder: _customMessageBuilder,
                  theme: DefaultChatTheme(
                    primaryColor: const Color(0xFF3B82F6),
                    secondaryColor: const Color(0xFFF3F4F6),
                    backgroundColor: Colors.white,
                    inputBackgroundColor: const Color(0xFFF3F4F6),
                    inputTextColor: Colors.black87,
                    inputBorderRadius: BorderRadius.circular(24),
                    messageBorderRadius: 20,
                    userAvatarNameColors: const [Color(0xFF3B82F6)],
                    sendButtonIcon: const Icon(
                      Icons.send_rounded,
                      color: Colors.black87,
                      size: 20,
                    ),
                  ),
                  typingIndicatorOptions: TypingIndicatorOptions(
                    typingMode: TypingIndicatorMode.avatar,
                    typingUsers: _isTyping ? [_bot] : const [],
                  ),
                  inputOptions: const InputOptions(
                    sendButtonVisibilityMode: SendButtonVisibilityMode.always,
                  ),
                  avatarBuilder: (author) {
                    if (author.id == _bot.id) {
                      return const CircleAvatar(
                        backgroundColor: Color(0xFF3B82F6),
                        radius: 16,
                        child: Icon(
                          Icons.smart_toy,
                          color: Colors.white,
                          size: 18,
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                if (_isInitializing && _messages.isEmpty)
                  const Center(
                    child: CircularProgressIndicator(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
