// Flutter imports:
import 'package:flutter/foundation.dart';

// Package imports:
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_bugfender/flutter_bugfender.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Project imports:
import 'package:msbridge/core/database/chat_history/chat_history.dart';
import 'package:msbridge/core/repo/chat_history_repo.dart';

class ChatHistoryProvider extends ChangeNotifier {
  static const String _historyEnabledKey = 'chat_history_enabled';

  bool _isHistoryEnabled = true;
  List<ChatHistory> _chatHistories = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  bool get isHistoryEnabled => _isHistoryEnabled;
  List<ChatHistory> get chatHistories => _chatHistories;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get historyCount => _chatHistories.length;

  ChatHistoryProvider() {
    _loadSettings();
    _loadChatHistories();
  }

  // Load settings from SharedPreferences
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isHistoryEnabled = prefs.getBool(_historyEnabledKey) ?? true;
      notifyListeners();
    } catch (e) {
      FlutterBugfender.sendCrash('Failed to load chat history settings: $e',
          StackTrace.current.toString());
      FlutterBugfender.error(
        'Failed to load chat history settings: $e',
      );

      _error = 'Failed to load settings: $e';
      notifyListeners();
    }
  }

  // Save settings to SharedPreferences
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_historyEnabledKey, _isHistoryEnabled);
    } catch (e) {
      FlutterBugfender.sendCrash('Failed to save chat history settings: $e',
          StackTrace.current.toString());
      FlutterBugfender.error(
        'Failed to save chat history settings: $e',
      );

      _error = 'Failed to save settings: $e';
      notifyListeners();
    }
  }

  // Toggle history enabled/disabled
  Future<void> toggleHistoryEnabled() async {
    _isHistoryEnabled = !_isHistoryEnabled;
    await _saveSettings();

    if (!_isHistoryEnabled) {
      FlutterBugfender.sendCrash(
          'Chat history disabled by user', StackTrace.current.toString());
      FlutterBugfender.error(
        'Chat history disabled by user',
      );
    } else {
      FlutterBugfender.sendCrash(
          'Chat history enabled by user', StackTrace.current.toString());
      FlutterBugfender.error(
        'Chat history enabled by user',
      );
    }

    notifyListeners();
  }

  // Load chat histories from Hive
  Future<void> _loadChatHistories() async {
    if (!_isHistoryEnabled) return;

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _chatHistories = await ChatHistoryRepo.getAllChatHistories();

      FlutterBugfender.sendCrash(
          'Loaded ${_chatHistories.length} chat histories',
          StackTrace.current.toString());
      FlutterBugfender.error(
        'Loaded ${_chatHistories.length} chat histories',
      );
    } catch (e) {
      FlutterBugfender.sendCrash(
          'Failed to load chat histories: $e', StackTrace.current.toString());
      FlutterBugfender.error(
        'Failed to load chat histories: $e',
      );
      _error = 'Failed to load chat histories: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Refresh chat histories
  Future<void> refreshChatHistories() async {
    await _loadChatHistories();
  }

  // Save a new chat history
  Future<void> saveChatHistory(ChatHistory chatHistory) async {
    if (!_isHistoryEnabled) return;

    try {
      await ChatHistoryRepo.saveChatHistory(chatHistory);

      // Add to local list and sort by last updated
      _chatHistories.add(chatHistory);
      _chatHistories.sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));

      await FirebaseCrashlytics.instance.log(
        'Chat history saved locally: ${chatHistory.id}',
      );

      notifyListeners();
    } catch (e) {
      FlutterBugfender.sendCrash('Failed to save chat history in provider: $e',
          StackTrace.current.toString());
      FlutterBugfender.error(
        'Failed to save chat history in provider: $e',
      );

      _error = 'Failed to save chat history: $e';
      notifyListeners();
    }
  }

  // Update existing chat history
  Future<void> updateChatHistory(ChatHistory chatHistory) async {
    if (!_isHistoryEnabled) return;

    try {
      await ChatHistoryRepo.updateChatHistory(chatHistory);

      // Update in local list
      final index = _chatHistories.indexWhere((h) => h.id == chatHistory.id);
      if (index != -1) {
        _chatHistories[index] = chatHistory;
        _chatHistories.sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));
      }

      FlutterBugfender.sendCrash(
          'Chat history updated locally: ${chatHistory.id}',
          StackTrace.current.toString());
      FlutterBugfender.error(
        'Chat history updated locally: ${chatHistory.id}',
      );

      notifyListeners();
    } catch (e) {
      FlutterBugfender.sendCrash(
          'Failed to update chat history in provider: $e',
          StackTrace.current.toString());
      FlutterBugfender.error(
        'Failed to update chat history in provider: $e',
      );

      _error = 'Failed to update chat history: $e';
      notifyListeners();
    }
  }

  // Delete a chat history
  Future<void> deleteChatHistory(String id) async {
    try {
      await ChatHistoryRepo.deleteChatHistory(id);

      // Remove from local list
      _chatHistories.removeWhere((h) => h.id == id);

      await FlutterBugfender.log('Chat history deleted: $id');

      notifyListeners();
    } catch (e) {
      FlutterBugfender.sendCrash(
          'Failed to delete chat history: $e', StackTrace.current.toString());
      FlutterBugfender.error(
        'Failed to delete chat history: $e',
      );

      _error = 'Failed to delete chat history: $e';
      notifyListeners();
    }
  }

  // Clear all chat histories
  Future<void> clearAllChatHistories() async {
    try {
      await ChatHistoryRepo.clearAllChatHistories();

      // Clear local list
      _chatHistories.clear();

      await FlutterBugfender.log('All chat histories cleared');

      notifyListeners();
    } catch (e) {
      await FlutterBugfender.sendCrash('Failed to clear all chat histories: $e',
          StackTrace.current.toString());
      await FlutterBugfender.error(
        'Failed to clear all chat histories: $e',
      );

      _error = 'Failed to clear chat histories: $e';
      notifyListeners();
    }
  }

  // Get a specific chat history by ID
  ChatHistory? getChatHistory(String id) {
    try {
      return _chatHistories.firstWhere((h) => h.id == id);
    } catch (e) {
      return null;
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
