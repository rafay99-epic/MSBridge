import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:msbridge/core/ai/notes_context_builder.dart';
import 'package:msbridge/config/config.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

class ChatMessage {
  final bool fromUser;
  final String text;
  final bool isError;
  final String? errorDetails;
  
  ChatMessage(this.fromUser, this.text, {this.isError = false, this.errorDetails});
  
  ChatMessage.error(this.fromUser, this.text, {this.errorDetails})
      : isError = true;
}

class NotesChatProvider extends ChangeNotifier {
  final List<ChatMessage> messages = [];
  GenerativeModel? _model;
  GenerativeModel? get model => _model;
  String? _contextJson;
  
  // Error handling states
  bool _isLoading = false;
  bool _hasError = false;
  String? _lastErrorMessage;
  
  // Getters for UI state
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String? get lastErrorMessage => _lastErrorMessage;

  Future<void> startSession(
      {required bool includePersonal, required bool includeMsNotes}) async {
    try {
      _clearError();
      _isLoading = true;
      notifyListeners();

      _model = GenerativeModel(
        model: 'gemini-1.5-pro-latest',
        apiKey: NoteSummaryAPI.apiKey,
        systemInstruction: Content.system(
          'You are an assistant that answers ONLY from the provided notes JSON. If the answer is not in the notes, say you don\'t know. Cite note titles in parentheses.',
        ),
      );

      // Build context based on what's requested
      if (includePersonal || includeMsNotes) {
        _contextJson = await NotesContextBuilder.buildJson(
          includePersonal: includePersonal,
          includeMsNotes: includeMsNotes,
        );
      }

      _isLoading = false;
      notifyListeners();
      
      // Log successful session start
      await _logCustomEvent('chat_session_started', {
        'includePersonal': includePersonal,
        'includeMsNotes': includeMsNotes,
        'hasContext': _contextJson != null,
      });
      
    } catch (e, stackTrace) {
      _setError('Failed to start chat session: ${e.toString()}', e, stackTrace);
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> ask(String question) async {
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

      // Prepare content for AI
      final content = [
        Content.system(
            'You are an assistant that answers ONLY from the provided notes JSON. If the answer is not in the notes, say you don\'t know. Cite note titles in parentheses.'),
        Content.text('NOTES_JSON:\n```json\n$_contextJson\n```'),
        Content.text('USER_QUESTION: $question'),
      ];

      // Generate AI response with timeout
      final response = await _model!.generateContent(content).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('AI response generation timed out', const Duration(seconds: 30));
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
      });

      return text;
      
    } catch (e, stackTrace) {
      _setError('Failed to generate AI response: ${e.toString()}', e, stackTrace);
      _isLoading = false;
      
      // Add error message to chat
      final errorMessage = _getUserFriendlyErrorMessage(e);
      messages.add(ChatMessage.error(false, errorMessage, errorDetails: e.toString()));
      
      notifyListeners();
      return null;
    }
  }

  // Clear all messages
  void clearMessages() {
    messages.clear();
    _clearError();
    notifyListeners();
  }

  // Remove last message (useful for retry functionality)
  void removeLastMessage() {
    if (messages.isNotEmpty) {
      messages.removeLast();
      notifyListeners();
    }
  }

  // Retry last question
  Future<String?> retryLastQuestion() async {
    if (messages.isEmpty) return null;
    
    // Find the last user question
    for (int i = messages.length - 1; i >= 0; i--) {
      if (messages[i].fromUser) {
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

  // Error handling methods
  void _setError(String message, Object? error, StackTrace? stackTrace) {
    _hasError = true;
    _lastErrorMessage = message;
    
    // Log to Firebase Crashlytics
    if (error != null) {
      FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace,
        reason: 'Chat Provider Error',
        information: [
          'Error: $message',
          'Provider: NotesChatProvider',
          'Timestamp: ${DateTime.now().toIso8601String()}',
        ],
      );
    }
  }

  void _clearError() {
    _hasError = false;
    _lastErrorMessage = null;
  }

  // Get user-friendly error messages
  String _getUserFriendlyErrorMessage(Object error) {
    if (error is TimeoutException) {
      return 'AI response is taking longer than expected. Please try again.';
    } else if (error.toString().contains('API key')) {
      return 'AI service configuration issue. Please contact support.';
    } else if (error.toString().contains('network') || error.toString().contains('connection')) {
      return 'Network connection issue. Please check your internet and try again.';
    } else if (error.toString().contains('quota') || error.toString().contains('limit')) {
      return 'AI service limit reached. Please try again later.';
    } else {
      return 'Sorry, I encountered an error. Please try again.';
    }
  }

  // Log custom events to Crashlytics
  Future<void> _logCustomEvent(String eventName, Map<String, dynamic> parameters) async {
    try {
      FirebaseCrashlytics.instance.log('Chat Provider Event: $eventName');
      FirebaseCrashlytics.instance.setCustomKey('event_$eventName', parameters.toString());
    } catch (e) {
      // Fallback if Crashlytics fails
    }
  }

  // Check if provider is in a valid state
  bool get isReady => _model != null && _contextJson != null && !_hasError;
  
  // Get current session status
  String get sessionStatus {
    if (_isLoading) return 'Loading...';
    if (_hasError) return 'Error: $_lastErrorMessage';
    if (_model == null) return 'Not initialized';
    if (_contextJson == null) return 'No context available';
    return 'Ready';
  }
}

// Custom timeout exception
class TimeoutException implements Exception {
  final String message;
  final Duration duration;
  
  TimeoutException(this.message, this.duration);
  
  @override
  String toString() => 'TimeoutException: $message after ${duration.inSeconds} seconds';
}
