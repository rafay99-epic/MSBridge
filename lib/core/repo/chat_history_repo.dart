import 'package:hive_flutter/hive_flutter.dart';
import 'package:msbridge/core/database/chat_history/chat_history.dart';
import 'package:msbridge/core/database/note_taking/note_taking.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

class ChatHistoryRepo {
  static const String _boxName = 'chat_history';
  static Box<ChatHistory>? _box;

  ChatHistoryRepo._();

  static final ChatHistoryRepo _instance = ChatHistoryRepo._();

  factory ChatHistoryRepo() => _instance;

  static Future<Box<ChatHistory>> getBox() async {
    if (_box == null || !_box!.isOpen) {
      try {
        _box = await Hive.openBox<ChatHistory>(_boxName);
      } catch (e) {
        await FirebaseCrashlytics.instance.recordError(
          e,
          null,
          reason: 'Failed to open chat history Hive box',
          information: ['Box name: $_boxName'],
        );
        throw Exception('Error opening Hive box "$_boxName": $e');
      }
    }
    return _box!;
  }

  // Save a new chat conversation
  static Future<void> saveChatHistory(ChatHistory chatHistory) async {
    try {
      final box = await getBox();
      await box.put(chatHistory.id, chatHistory);

      await FirebaseCrashlytics.instance.log(
        'Chat history saved: ${chatHistory.id} with ${chatHistory.messages.length} messages',
      );
    } catch (e, stackTrace) {
      await FirebaseCrashlytics.instance.recordError(
        e,
        stackTrace,
        reason: 'Failed to save chat history',
        information: ['Chat ID: ${chatHistory.id}'],
      );
      throw Exception('Error saving chat history: $e');
    }
  }

  // Update existing chat history
  static Future<void> updateChatHistory(ChatHistory chatHistory) async {
    try {
      final box = await getBox();
      await box.put(chatHistory.id, chatHistory);

      await FirebaseCrashlytics.instance.log(
        'Chat history updated: ${chatHistory.id}',
      );
    } catch (e, stackTrace) {
      await FirebaseCrashlytics.instance.recordError(
        e,
        stackTrace,
        reason: 'Failed to update chat history',
        information: ['Chat ID: ${chatHistory.id}'],
      );
      throw Exception('Error updating chat history: $e');
    }
  }

  // Get all chat histories
  static Future<List<ChatHistory>> getAllChatHistories() async {
    try {
      final box = await getBox();
      final histories = box.values.toList()
        ..sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));

      await FirebaseCrashlytics.instance.log(
        'Retrieved ${histories.length} chat histories',
      );

      return histories;
    } catch (e, stackTrace) {
      await FirebaseCrashlytics.instance.recordError(
        e,
        stackTrace,
        reason: 'Failed to retrieve chat histories',
      );
      throw Exception('Error retrieving chat histories: $e');
    }
  }

  // Get a specific chat history by ID
  static Future<ChatHistory?> getChatHistory(String id) async {
    try {
      final box = await getBox();
      return box.get(id);
    } catch (e, stackTrace) {
      await FirebaseCrashlytics.instance.recordError(
        e,
        stackTrace,
        reason: 'Failed to retrieve specific chat history',
        information: ['Chat ID: $id'],
      );
      throw Exception('Error retrieving chat history: $e');
    }
  }

  // Delete a chat history
  static Future<void> deleteChatHistory(String id) async {
    try {
      final box = await getBox();
      await box.delete(id);

      await FirebaseCrashlytics.instance.log(
        'Chat history deleted: $id',
      );
    } catch (e, stackTrace) {
      await FirebaseCrashlytics.instance.recordError(
        e,
        stackTrace,
        reason: 'Failed to delete chat history',
        information: ['Chat ID: $id'],
      );
      throw Exception('Error deleting chat history: $e');
    }
  }

  // Clear all chat histories
  static Future<void> clearAllChatHistories() async {
    try {
      final box = await getBox();
      await box.clear();

      await FirebaseCrashlytics.instance.log(
        'All chat histories cleared',
      );
    } catch (e, stackTrace) {
      await FirebaseCrashlytics.instance.recordError(
        e,
        stackTrace,
        reason: 'Failed to clear all chat histories',
      );
      throw Exception('Error clearing chat histories: $e');
    }
  }

  // Get chat history count
  static Future<int> getChatHistoryCount() async {
    try {
      final box = await getBox();
      return box.length;
    } catch (e, stackTrace) {
      await FirebaseCrashlytics.instance.recordError(
        e,
        stackTrace,
        reason: 'Failed to get chat history count',
      );
      throw Exception('Error getting chat history count: $e');
    }
  }
}
