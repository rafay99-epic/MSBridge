import 'package:flutter/material.dart';
import 'package:msbridge/core/repo/note_summary_repo.dart';

class NoteSummaryProvider with ChangeNotifier {
  final NoteSummaryRepo _repository;
  String? _aiSummary;
  bool _isGeneratingSummary = false;

  NoteSummaryProvider({required String apiKey})
      : _repository = NoteSummaryRepo(apiKey: apiKey);

  String? get aiSummary => _aiSummary;
  bool get isGeneratingSummary => _isGeneratingSummary;

  Future<void> summarizeNote(String noteContent) async {
    if (noteContent.trim().isEmpty) return;

    _isGeneratingSummary = true;
    _aiSummary = null;
    notifyListeners();

    try {
      final summary = await _repository.summarizeNote(noteContent);
      _aiSummary = summary;
      notifyListeners();
    } catch (e) {
      _aiSummary = "Error generating summary: $e";
      notifyListeners();
    } finally {
      _isGeneratingSummary = false;
      notifyListeners();
    }
  }
}
