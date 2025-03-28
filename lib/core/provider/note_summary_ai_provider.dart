import 'package:flutter/material.dart';
import 'package:msbridge/core/repo/note_summary_repo.dart';

class NoteSumaryProvider with ChangeNotifier {
  final NoteSummaryRepo _repository;
  final List<Map<String, String>> _messages = [];
  bool _isTyping = false;

  NoteSumaryProvider({required String apiKey})
      : _repository = NoteSummaryRepo(apiKey: apiKey);

  List<Map<String, String>> get messages => _messages;
  bool get isTyping => _isTyping;

  Future<void> summarizeNote(String noteContent) async {
    if (noteContent.trim().isEmpty) return;

    _messages.add({"role": "user", "content": "Summarizing Note..."});
    _isTyping = true;
    notifyListeners();

    try {
      final aiResponse = await _repository.summarizeNote(noteContent);
      _messages.add({"role": "ai", "content": aiResponse});
    } catch (e) {
      print("Error in NoteSumaryProvider: $e");
      _messages.add({
        "role": "ai",
        "content": "Error: Unable to generate a summary. Please try again."
      });
    } finally {
      _isTyping = false;
      notifyListeners();
    }
  }

  Future<void> sendMessage(String userMessage) async {
    if (userMessage.trim().isEmpty) return;

    _messages.add({"role": "user", "content": userMessage});
    _isTyping = true;
    notifyListeners();

    try {
      final aiResponse = await _repository.generateResponse(userMessage);
      _messages.add({"role": "ai", "content": aiResponse});
    } catch (e) {
      _messages.add({
        "role": "ai",
        "content": "Error: Unable to generate a response. Please try again."
      });
    } finally {
      _isTyping = false;
      notifyListeners();
    }
  }
}
