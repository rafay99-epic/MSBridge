import 'package:flutter/material.dart';
import 'package:msbridge/core/repo/note_summary_repo.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:msbridge/config/ai_model_choice.dart';

class NoteSummaryProvider with ChangeNotifier {
  late NoteSummaryRepo _repository;
  String? _aiSummary;
  bool _isGeneratingSummary = false;
  final String _apiKey;
  String _modelName;

  NoteSummaryProvider({required String apiKey, String? modelName})
      : _apiKey = apiKey,
        _modelName = modelName ?? 'gemini-1.5-pro-latest' {
    _repository = NoteSummaryRepo(apiKey: apiKey, modelName: _modelName);
    _loadSelectedModel();
  }

  String? get aiSummary => _aiSummary;
  bool get isGeneratingSummary => _isGeneratingSummary;

  Future<void> _loadSelectedModel() async {
    String modelName = await _getSelectedModelName();
    _modelName = modelName;
    _updateRepository();
    notifyListeners();
  }

  Future<String> _getSelectedModelName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AIModelsConfig.selectedModelKey) ??
        'gemini-1.5-pro-latest';
  }

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

  Future<void> updateModel() async {
    String modelName = await _getSelectedModelName();
    _modelName = modelName;
    _updateRepository();
    notifyListeners();
  }

  void _updateRepository() {
    _repository = NoteSummaryRepo(apiKey: _apiKey, modelName: _modelName);
    notifyListeners();
  }
}
