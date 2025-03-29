import 'package:google_generative_ai/google_generative_ai.dart';

class NoteSummaryRepo {
  final GenerativeModel _model;

  NoteSummaryRepo({required String apiKey, required String modelName})
      : _model = GenerativeModel(
          model: modelName,
          apiKey: apiKey,
        );

  String _sanitizePrompt(String prompt) {
    final sanitized = prompt.trim();
    if (sanitized.isEmpty) {
      throw ArgumentError('Prompt cannot be empty');
    }
    return sanitized;
  }

  Future<String> summarizeNote(String noteContent) async {
    final prompt = """
    I have the following note, and I need a concise and informative summary. Please focus on capturing the key concepts, important facts, and any action items mentioned.  
    If there are heading points, please highlight them using Markdown headings (e.g., ## Heading).
    If the note discusses any problems, please briefly describe the problem and, if a solution is provided in the note, mention the solution as well.
    The summary should be well-structured and easy to understand, as if explaining the main points to someone who hasn't read the original note.  Limit the summary to approximately 150 words.

    Note:
    $noteContent

    Summary:
  """;

    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      return response.text ?? "I couldn't generate a summary.";
    } catch (e) {
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
