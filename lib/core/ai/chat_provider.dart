import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bugfender/flutter_bugfender.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:msbridge/core/ai/notes_context_builder.dart';
import 'package:msbridge/config/ai_model_choice.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:msbridge/config/config.dart';
import 'package:msbridge/core/database/chat_history/chat_history.dart';
import 'package:msbridge/core/repo/chat_history_repo.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;

class ChatMessage {
  final bool fromUser;
  final String text;
  final bool isError;
  final String? errorDetails;
  final List<String> imageUrls; // optional attachments to render with message

  ChatMessage(
    this.fromUser,
    this.text, {
    this.isError = false,
    this.errorDetails,
    List<String>? imageUrls,
  }) : imageUrls = imageUrls ?? const [];

  ChatMessage.error(this.fromUser, this.text, {this.errorDetails})
      : isError = true,
        imageUrls = const [];
}

class ChatProvider extends ChangeNotifier {
  final List<ChatMessage> messages = [];
  GenerativeModel? _model;
  String? _contextJson;
  String _modelName = AIModelsConfig.models.first.modelName;

  // Pending attachments to be included with the next ask() call
  final List<String> _pendingImageUrls = [];

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
  List<String> get pendingImageUrls => List.unmodifiable(_pendingImageUrls);

  void addPendingImageUrl(String url) {
    if (url.trim().isEmpty) return;
    _pendingImageUrls.add(url.trim());
    notifyListeners();
  }

  void clearPendingImages() {
    _pendingImageUrls.clear();
    notifyListeners();
  }

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
    } catch (e) {
      // Try fallback to a stable model
      try {
        _modelName = 'gemini-2.5-pro';
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
      } catch (fallbackError) {
        _setError('Failed to initialize AI model: ${e.toString()}', e);
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
      await FlutterBugfender.log(
        'Building AI context: includePersonal=$includePersonal, includeMsNotes=$includeMsNotes',
      );
      _contextJson = await NotesContextBuilder.buildJson(
        includePersonal: includePersonal,
        includeMsNotes: includeMsNotes,
      );
      await FlutterBugfender.log(
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
      _setError('Failed to start chat session: ${e.toString()}', e);
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
      _setError('Question cannot be empty', null);
      return null;
    }

    try {
      _clearError();
      _isLoading = true;
      notifyListeners();

      // Ensure session/model based on toggles
      if (includePersonal || includeMsNotes) {
        if (_model == null || _contextJson == null) {
          await startSession(
              includePersonal: includePersonal, includeMsNotes: includeMsNotes);
          if (_hasError) return null;
        }
      } else {
        if (_model == null) {
          await _initializeModel();
          if (_hasError) return null;
        }
      }

      // Add user message merged with any pending images
      final List<String> attachments = List<String>.from(_pendingImageUrls);
      messages.add(ChatMessage(true, question, imageUrls: attachments));
      notifyListeners();

      // Save to chat history if enabled
      if (_isHistoryEnabled) {
        await saveChatToHistory(
          includePersonal: includePersonal,
          includeMsNotes: includeMsNotes,
        );
      }

      // Prepare content for AI (with or without notes context)
      await FlutterBugfender.log(
        'Preparing AI content. Context length: ${_contextJson?.length ?? 0}',
      );
      if (_contextJson != null && _contextJson!.isNotEmpty) {
        await FlutterBugfender.log(
          'Context preview: ${_contextJson!.substring(0, _contextJson!.length > 200 ? 200 : _contextJson!.length)}...',
        );
      }

      // Build content including any pending image attachments
      final content = await _buildGeminiContent(question,
          includePersonal: includePersonal, includeMsNotes: includeMsNotes);

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

      // Persist history again to include the AI response
      if (_isHistoryEnabled) {
        await saveChatToHistory(
          includePersonal: includePersonal,
          includeMsNotes: includeMsNotes,
        );
      }

      // After a successful response, clear any pending attachments
      _pendingImageUrls.clear();
      return text;
    } catch (e) {
      _setError('Failed to generate AI response: ${e.toString()}', e);
      _isLoading = false;

      // Add error message to chat
      final errorMessage = _getUserFriendlyErrorMessage(e);
      messages.add(
          ChatMessage.error(false, errorMessage, errorDetails: e.toString()));

      // Persist history with the error message so restores match the UI state
      if (_isHistoryEnabled) {
        await saveChatToHistory(
          includePersonal: includePersonal,
          includeMsNotes: includeMsNotes,
        );
      }

      notifyListeners();
      return null;
    }
  }

  // Removed unused text-only URL collector; image bytes are now attached via _buildGeminiContent.

  Future<List<Content>> _buildGeminiContent(String question,
      {required bool includePersonal, required bool includeMsNotes}) async {
    final List<Part> parts = [];
    if (includePersonal || includeMsNotes) {
      parts.add(TextPart(
          '''You are a helpful AI assistant that has access to the user's personal notes and MS Notes. Answer questions based on the provided context. If the answer is not in the notes, say you don't know. Cite note titles in parentheses when referencing specific notes.'''));
    } else {
      parts.add(TextPart(
          'You are a helpful AI assistant having a general conversation.'));
    }

    final RegExp img = RegExp(
        r'^(http|https)://.*\.(png|jpg|jpeg|webp)(\?.*)?$',
        caseSensitive: false);
    final List<String> urls =
        _pendingImageUrls.where((u) => img.hasMatch(u)).take(2).toList();

    for (final url in urls) {
      try {
        final resp = await http.get(Uri.parse(url)).timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            FlutterBugfender.error('Image fetch timed out');
            throw TimeoutException(
                'Image fetch timed out', const Duration(seconds: 30));
          },
        );
        if (resp.statusCode == 200 && resp.bodyBytes.isNotEmpty) {
          final String mime = _inferMimeFromUrl(url);
          parts.add(DataPart(mime, resp.bodyBytes));
        }
      } on TimeoutException catch (e) {
        await FlutterBugfender.error(
          'Image fetch timed out +  $e',
        );
      } catch (e) {
        await FlutterBugfender.error(
          'Failed to fetch image bytes for Gemini: $e',
        );
      }
    }

    // Include notes context only if enabled
    if (includePersonal || includeMsNotes) {
      parts.add(TextPart(
          '''\nNOTES_CONTEXT:\n```json\n${_contextJson ?? ''}\n```\n'''));
    }
    parts.add(TextPart('USER_QUESTION: $question'));
    return [Content.multi(parts)];
  }

  String _inferMimeFromUrl(String url) {
    final lower = url.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
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
  void _setError(String message, dynamic error) {
    _hasError = true;
    _lastErrorMessage = message;

    // Log to Firebase Crashlytics
    if (error != null) {
      FlutterBugfender.error('Chat Provider Error: $message');
    }
    FlutterBugfender.log('Chat Provider Error: $message');

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
      FlutterBugfender.log('Chat Provider Event: $eventName');
    } catch (e) {
      FlutterBugfender.error('Failed to log to Crashlytics: $e');
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
      _currentChatId ??= const Uuid().v4();

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
                imageUrls: msg.imageUrls.isEmpty ? null : msg.imageUrls,
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

      await FlutterBugfender.log(
        'Chat history saved: ${chatHistory.id} with ${historyMessages.length} messages',
      );
    } catch (e) {
      await FlutterBugfender.error('Failed to save chat history: $e');
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
          imageUrls: historyMsg.imageUrls,
        ));
      }

      // Update context based on history settings in the background to avoid UI jank
      if (chatHistory.includePersonal || chatHistory.includeMsNotes) {
        Future.microtask(() async {
          try {
            _contextJson = await NotesContextBuilder.buildJson(
              includePersonal: chatHistory.includePersonal,
              includeMsNotes: chatHistory.includeMsNotes,
            );
            notifyListeners();
          } catch (e) {
            await FlutterBugfender.error(
              'Failed to build context after loading history: $e',
            );
          }
        });
      }

      // Initialize model if needed without blocking the UI
      if (_model == null) {
        Future.microtask(() async {
          try {
            await _initializeModel();
            notifyListeners();
          } catch (e) {
            await FlutterBugfender.error(
              'Failed to initialize model after loading history: $e',
            );
          }
        });
      }

      _clearError();
      notifyListeners();

      await FlutterBugfender.log(
        'Chat loaded from history: ${chatHistory.id}',
      );
    } catch (e) {
      await FlutterBugfender.error(
        'Failed to load chat from history: $e',
      );
      _setError('Failed to load chat history', e);
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
