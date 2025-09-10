import 'package:flutter/material.dart';
import 'package:flutter_bugfender/flutter_bugfender.dart';
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
        _modelName = modelName ?? AIModelsConfig.models.first.modelName {
    _repository = NoteSummaryRepo();
    _loadSelectedModel();
  }

  String? get aiSummary => _aiSummary;
  bool get isGeneratingSummary => _isGeneratingSummary;

  Future<void> _loadSelectedModel() async {
    String modelName = await _getSelectedModelName();
    _modelName = modelName;
    notifyListeners();
  }

  Future<String> _getSelectedModelName() async {
    final prefs = await SharedPreferences.getInstance();
    final selectedModelKey = prefs.getString(AIModelsConfig.selectedModelKey);

    if (selectedModelKey != null) {
      // Find the model by key
      final selectedModel = AIModelsConfig.models.firstWhere(
          (model) => model.modelName == selectedModelKey,
          orElse: () => AIModelsConfig.models.first);
      return selectedModel.modelName;
    }

    return AIModelsConfig.models.first.modelName;
  }

  Future<void> summarizeNote(String noteContent) async {
    if (noteContent.trim().isEmpty) return;

    _isGeneratingSummary = true;
    _aiSummary = null;
    notifyListeners();

    try {
      final summary =
          await _repository.summarizeNote(_apiKey, _modelName, noteContent);
      _aiSummary = summary;
      notifyListeners();
    } catch (e) {
      _aiSummary = "Error generating summary: $e";
      FlutterBugfender.sendCrash(
          'Error generating summary: $e', StackTrace.current.toString());
      FlutterBugfender.error(
        'Error generating summary: $e',
      );
      notifyListeners();
    } finally {
      _isGeneratingSummary = false;
      notifyListeners();
    }
  }

  Future<void> updateModel() async {
    String modelName = await _getSelectedModelName();
    _modelName = modelName;
    notifyListeners();
  }
}
