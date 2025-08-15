import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:msbridge/core/ai/notes_context_builder.dart';
import 'package:msbridge/config/ai_model_choice.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:msbridge/config/config.dart';
import 'package:msbridge/core/database/chat_history/chat_history.dart';
import 'package:msbridge/core/repo/chat_history_repo.dart';
import 'package:uuid/uuid.dart';

class ChatMessage {
  final bool fromUser;
  final String text;
  final bool isError;
  final String? errorDetails;

  ChatMessage(this.fromUser, this.text,
      {this.isError = false, this.errorDetails});

  ChatMessage.error(this.fromUser, this.text, {this.errorDetails})
      : isError = true;
}

class ChatProvider extends ChangeNotifier {
  final List<ChatMessage> messages = [];
  GenerativeModel? _model;
  String? _contextJson;
  String _modelName = AIModelsConfig.models.first.modelName;

  // Chat history properties
  String? _currentChatId;
  bool _isHistoryEnabled = true;

  // Error handling states
  bool _isLoading = false;
  bool _hasError = false;
  String? _lastErrorMessage;

  // Getters for UI state
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String? get lastErrorMessage => _lastErrorMessage;
  GenerativeModel? get model => _model;
  String get modelName => _modelName;

  // Chat history getters
  String? get currentChatId => _currentChatId;
  bool get isHistoryEnabled => _isHistoryEnabled;

  // Initialize the chat model
  Future<void> _initializeModel() async {
    try {
      // Load the selected model
      await _loadSelectedModel();

      _model = GenerativeModel(
        model: _modelName,
        apiKey: ChatAPI.apiKey,
        generationConfig: GenerationConfig(
          temperature: 0.7,
          topK: 40,
          topP: 0.95,
          maxOutputTokens: 2048,
        ),
      );
    } catch (e, stackTrace) {
      // Try fallback to a stable model
      try {
        _modelName = 'gemini-1.5-pro';
        _model = GenerativeModel(
          model: _modelName,
          apiKey: ChatAPI.apiKey,
          generationConfig: GenerationConfig(
            temperature: 0.7,
            topK: 40,
            topP: 0.95,
            maxOutputTokens: 2048,
          ),
        );
      } catch (fallbackError, _) {
        _setError(
            'Failed to initialize AI model: ${e.toString()}', e, stackTrace);
      }
    }
  }

  // Load the selected AI model
  Future<void> _loadSelectedModel() async {
    final prefs = await SharedPreferences.getInstance();
    final selectedModelKey = prefs.getString(AIModelsConfig.selectedModelKey);

    if (selectedModelKey != null) {
      // Find the model by key
      final selectedModel = AIModelsConfig.models.firstWhere(
          (model) => model.modelName == selectedModelKey,
          orElse: () => AIModelsConfig.models.first);
      _modelName = selectedModel.modelName;
    } else {
      _modelName = AIModelsConfig.models.first.modelName;
    }
  }

  // Start a new chat session
  Future<bool> startSession({
    bool includePersonal = true,
    bool includeMsNotes = true,
  }) async {
    try {
      _clearError();
      _isLoading = true;
      notifyListeners();

      // Initialize model if not already done
      if (_model == null) {
        await _initializeModel();
        if (_hasError) return false;
      }

      // Build context from notes
      await FirebaseCrashlytics.instance.log(
        'Building AI context: includePersonal=$includePersonal, includeMsNotes=$includeMsNotes',
      );
      _contextJson = await NotesContextBuilder.buildJson(
        includePersonal: includePersonal,
        includeMsNotes: includeMsNotes,
      );
      await FirebaseCrashlytics.instance.log(
        'AI context built successfully. Length: ${_contextJson?.length ?? 0} characters',
      );

      _isLoading = false;
      notifyListeners();

      // Log successful session start
      await _logCustomEvent('chat_session_started', {
        'includePersonal': includePersonal,
        'includeMsNotes': includeMsNotes,
        'hasContext': _contextJson != null,
      });

      return true;
    } catch (e, stackTrace) {
      _setError('Failed to start chat session: ${e.toString()}', e, stackTrace);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Ask a question to the AI
  Future<String?> ask(
    String question, {
    bool includePersonal = true,
    bool includeMsNotes = true,
  }) async {
    if (question.trim().isEmpty) {
      _setError('Question cannot be empty', null, null);
      return null;
    }

    try {
      _clearError();
      _isLoading = true;
      notifyListeners();

      // Ensure session is initialized
      if (_model == null || _contextJson == null) {
        await startSession(includePersonal: true, includeMsNotes: true);

        // Check if session initialization failed
        if (_hasError) {
          return null;
        }
      }

      // Add user message
      messages.add(ChatMessage(true, question));
      notifyListeners();

      // Save to chat history if enabled
      if (_isHistoryEnabled) {
        await saveChatToHistory(
          includePersonal: includePersonal,
          includeMsNotes: includeMsNotes,
        );
      }

      // Prepare content for AI with context from notes
      await FirebaseCrashlytics.instance.log(
        'Preparing AI content. Context length: ${_contextJson?.length ?? 0}',
      );
      if (_contextJson != null && _contextJson!.isNotEmpty) {
        await FirebaseCrashlytics.instance.log(
          'Context preview: ${_contextJson!.substring(0, _contextJson!.length > 200 ? 200 : _contextJson!.length)}...',
        );
      }

      final content = [
        Content.text(
            '''You are a helpful AI assistant that has access to the user's personal notes and MS Notes. Answer questions based on the provided context. If the answer is not in the notes, say you don't know. Cite note titles in parentheses when referencing specific notes.

NOTES_CONTEXT:
```json
$_contextJson
```

USER_QUESTION: $question'''),
      ];

      // Generate AI response with timeout
      final response = await _model!.generateContent(content).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException(
              'AI response generation timed out', const Duration(seconds: 30));
        },
      );

      final text = response.text ?? 'No response received from AI.';

      // Add AI response
      messages.add(ChatMessage(false, text));

      _isLoading = false;
      notifyListeners();

      // Log successful response
      await _logCustomEvent('ai_response_generated', {
        'questionLength': question.length,
        'responseLength': text.length,
        'hasContext': _contextJson != null,
        'modelUsed': _modelName,
      });

      return text;
    } catch (e, stackTrace) {
      _setError(
          'Failed to generate AI response: ${e.toString()}', e, stackTrace);
      _isLoading = false;

      // Add error message to chat
      final errorMessage = _getUserFriendlyErrorMessage(e);
      messages.add(
          ChatMessage.error(false, errorMessage, errorDetails: e.toString()));

      notifyListeners();
      return null;
    }
  }

  // Retry the last question
  Future<String?> retryLastQuestion() async {
    if (messages.isEmpty) return null;

    // Find the last user question
    for (int i = messages.length - 1; i >= 0; i--) {
      if (messages[i].fromUser && !messages[i].isError) {
        final question = messages[i].text;
        // Remove the error message if it exists
        if (i + 1 < messages.length && messages[i + 1].isError) {
          messages.removeAt(i + 1);
        }
        return await ask(question);
      }
    }
    return null;
  }

  // Clear all messages
  void clearChat() {
    messages.clear();
    _clearError();
    notifyListeners();
  }

  // Clear error state
  void _clearError() {
    _hasError = false;
    _lastErrorMessage = null;
    notifyListeners();
  }

  // Set error state
  void _setError(String message, dynamic error, StackTrace? stackTrace) {
    _hasError = true;
    _lastErrorMessage = message;

    // Log to Firebase Crashlytics
    if (error != null) {
      FirebaseCrashlytics.instance.recordError(error, stackTrace);
    }
    FirebaseCrashlytics.instance.log('Chat Provider Error: $message');

    notifyListeners();
  }

  // Get user-friendly error message
  String _getUserFriendlyErrorMessage(dynamic error) {
    if (error.toString().contains('timeout')) {
      return 'Request timed out. Please try again.';
    } else if (error.toString().contains('API key')) {
      return 'AI service configuration issue. Please contact support.';
    } else if (error.toString().contains('network') ||
        error.toString().contains('connection')) {
      return 'Network connection issue. Please check your internet and try again.';
    } else if (error.toString().contains('quota') ||
        error.toString().contains('limit')) {
      return 'AI service limit reached. Please try again later.';
    } else {
      return 'An unexpected error occurred. Please try again.';
    }
  }

  Future<void> _logCustomEvent(
      String eventName, Map<String, dynamic> parameters) async {
    try {
      FirebaseCrashlytics.instance.log('Chat Provider Event: $eventName');
      FirebaseCrashlytics.instance
          .setCustomKey('event_$eventName', parameters.toString());
    } catch (e) {
      // Fallback if Crashlytics fails
      debugPrint('Failed to log to Crashlytics: $e');
    }
  }

  // Check if provider is in a valid state
  bool get isReady => _model != null && _contextJson != null && !_hasError;

  // Get current session status
  String get sessionStatus {
    if (_model == null) return 'Initializing...';
    if (_contextJson == null) return 'No context available';
    if (_isLoading) return 'Processing...';
    if (_hasError) return 'Error occurred';
    return 'Ready (${_modelName.split('-').first})';
  }

  // Update AI model and refresh session
  Future<void> updateModel() async {
    await _loadSelectedModel();
    // Reinitialize the model with new selection
    _model = null;
    await _initializeModel();
    notifyListeners();
  }

  // Chat History Methods

  // Set history enabled state
  void setHistoryEnabled(bool enabled) {
    _isHistoryEnabled = enabled;
    notifyListeners();
  }

  // Save current chat to history
  Future<void> saveChatToHistory({
    bool includePersonal = true,
    bool includeMsNotes = true,
  }) async {
    if (!_isHistoryEnabled || messages.isEmpty) return;

    try {
      // Generate chat ID if not exists
      if (_currentChatId == null) {
        _currentChatId = const Uuid().v4();
      }

      // Create chat title from first user message
      String title = 'AI Chat';
      if (messages.isNotEmpty) {
        final firstUserMessage = messages.firstWhere(
          (msg) => msg.fromUser,
          orElse: () => messages.first,
        );
        title = firstUserMessage.text.length > 50
            ? '${firstUserMessage.text.substring(0, 50)}...'
            : firstUserMessage.text;
      }

      // Convert messages to history format
      final historyMessages = messages
          .map((msg) => ChatHistoryMessage(
                text: msg.text,
                fromUser: msg.fromUser,
                timestamp: DateTime.now(),
                isError: msg.isError,
                errorDetails: msg.errorDetails,
              ))
          .toList();

      // Create chat history object
      final chatHistory = ChatHistory(
        id: _currentChatId!,
        title: title,
        messages: historyMessages,
        createdAt: DateTime.now(),
        lastUpdated: DateTime.now(),
        includePersonal: includePersonal,
        includeMsNotes: includeMsNotes,
        modelName: _modelName,
      );

      // Save to Hive
      await ChatHistoryRepo.saveChatHistory(chatHistory);

      await FirebaseCrashlytics.instance.log(
        'Chat history saved: ${chatHistory.id} with ${historyMessages.length} messages',
      );
    } catch (e, stackTrace) {
      await FirebaseCrashlytics.instance.recordError(
        e,
        stackTrace,
        reason: 'Failed to save chat history',
        information: ['Messages count: ${messages.length}'],
      );
    }
  }

  // Load chat from history
  Future<void> loadChatFromHistory(ChatHistory chatHistory) async {
    try {
      // Clear current chat
      messages.clear();
      _currentChatId = chatHistory.id;
      _modelName = chatHistory.modelName;

      // Convert history messages back to chat messages
      for (final historyMsg in chatHistory.messages) {
        messages.add(ChatMessage(
          historyMsg.fromUser,
          historyMsg.text,
          isError: historyMsg.isError,
          errorDetails: historyMsg.errorDetails,
        ));
      }

      // Update context based on history settings
      if (chatHistory.includePersonal || chatHistory.includeMsNotes) {
        _contextJson = await NotesContextBuilder.buildJson(
          includePersonal: chatHistory.includePersonal,
          includeMsNotes: chatHistory.includeMsNotes,
        );
      }

      // Initialize model if needed
      if (_model == null) {
        await _initializeModel();
      }

      _clearError();
      notifyListeners();

      await FirebaseCrashlytics.instance.log(
        'Chat loaded from history: ${chatHistory.id}',
      );
    } catch (e, stackTrace) {
      await FirebaseCrashlytics.instance.recordError(
        e,
        stackTrace,
        reason: 'Failed to load chat from history',
        information: ['Chat ID: ${chatHistory.id}'],
      );
      _setError('Failed to load chat history', e, stackTrace);
    }
  }

  // Start new chat session
  void startNewChat() {
    messages.clear();
    _currentChatId = null;
    _contextJson = null;
    _clearError();
    notifyListeners();
  }
}

// Custom timeout exception
class TimeoutException implements Exception {
  final String message;
  final Duration duration;

  TimeoutException(this.message, this.duration);

  @override
  String toString() =>
      'TimeoutException: $message after ${duration.inSeconds} seconds';
}
