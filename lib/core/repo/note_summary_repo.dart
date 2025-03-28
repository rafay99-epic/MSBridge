import 'package:google_generative_ai/google_generative_ai.dart';

class NoteSummaryRepo {
  final GenerativeModel _model;

  NoteSummaryRepo({required String apiKey})
      : _model = GenerativeModel(
          model: 'gemini-1.5-pro',
          apiKey: apiKey,
        );

  /// Validates and sanitizes the input prompt
  String _sanitizePrompt(String prompt) {
    final sanitized = prompt.trim();
    if (sanitized.isEmpty) {
      throw ArgumentError('Prompt cannot be empty');
    }
    return sanitized;
  }

  /// Generates a summary for the given note content.
  Future<String> summarizeNote(String noteContent) async {
    //  Define the prompt for summarization.  Make it specific!
    final prompt =
        "Summarize the following note.  Focus on the key points and provide a concise overview. Keep the summary under 100 words:\n\n$noteContent"; //Improved Prompt

    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      return response.text ?? "I couldn't generate a summary.";
    } catch (e) {
      print("Error during summarization: $e"); // Added error logging
      return "An error occurred while generating the summary.";
    }
  }

  Future<String> generateResponse(String prompt) async {
    try {
      final sanitizedPrompt = _sanitizePrompt(prompt);
      final content = [Content.text(sanitizedPrompt)];
      final response = await _model.generateContent(content);

      return response.text ?? "I couldn't generate a response.";
    } catch (e) {
      if (e is ArgumentError) {
        return "Invalid input: ${e.message}";
      }
      return "An error occurred while processing your request.";
    }
  }
}
