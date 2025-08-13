import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:msbridge/core/ai/notes_context_builder.dart';
import 'package:msbridge/config/config.dart';

class ChatMessage {
  final bool fromUser;
  final String text;
  ChatMessage(this.fromUser, this.text);
}

class NotesChatProvider extends ChangeNotifier {
  final List<ChatMessage> messages = [];
  GenerativeModel? _model;
  GenerativeModel? get model => _model;
  String? _contextJson;

  Future<void> startSession({required bool includePersonal, required bool includeMsNotes}) async {
    _model = GenerativeModel(model: 'gemini-1.5-pro-latest', apiKey: NoteSummaryAPI.apiKey);
    _contextJson = await NotesContextBuilder.buildJson(includePersonal: includePersonal, includeMsNotes: includeMsNotes);
    messages.clear();
    notifyListeners();
  }

  Future<String> ask(String question) async {
    if (_model == null || _contextJson == null) {
      await startSession(includePersonal: true, includeMsNotes: true);
    }
    messages.add(ChatMessage(true, question));
    notifyListeners();

    final content = [
      Content.system('You are an assistant that answers ONLY from the provided notes JSON. If the answer is not in the notes, say you don\'t know. Cite note titles in parentheses.'),
      Content.text('NOTES_JSON:\n```json\n$_contextJson\n```'),
      Content.text('USER_QUESTION: $question'),
    ];
    final response = await _model!.generateContent(content);
    final text = response.text ?? 'No response.';
    messages.add(ChatMessage(false, text));
    notifyListeners();
    return text;
  }
}
