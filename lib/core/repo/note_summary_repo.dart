import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class NoteSummaryRepo {
  NoteSummaryRepo();

  String _sanitizePrompt(String prompt) {
    final sanitized = prompt.trim();
    if (sanitized.isEmpty) {
      throw ArgumentError('Prompt cannot be empty');
    }
    return sanitized;
  }

  static Future<String> _summarizeNoteInBackground(
      Map<String, dynamic> args) async {
    final apiKey = args['apiKey'] as String;
    final modelName = args['modelName'] as String;
    final noteContent = args['noteContent'] as String;

    final model = GenerativeModel(model: modelName, apiKey: apiKey);

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
      final response = await model.generateContent(content);

      return response.text ?? "I couldn't generate a summary.";
    } catch (e) {
      return "An error occurred while generating the summary: $e";
    }
  }

  Future<String> summarizeNote(
      String apiKey, String modelName, String noteContent) async {
    try {
      return await compute(_summarizeNoteInBackground, {
        'apiKey': apiKey,
        'modelName': modelName,
        'noteContent': noteContent,
      });
    } catch (e) {
      return "An error occurred while initiating the summary process: $e";
    }
  }

  static Future<String> _generateResponseInBackground(
      Map<String, dynamic> args) async {
    final apiKey = args['apiKey'] as String;
    final modelName = args['modelName'] as String;
    final prompt = args['prompt'] as String;

    final model = GenerativeModel(model: modelName, apiKey: apiKey);

    try {
      final sanitizedPrompt = prompt;
      final content = [Content.text(sanitizedPrompt)];
      final response = await model.generateContent(content);

      return response.text ?? "I couldn't generate a response.";
    } catch (e) {
      if (e is ArgumentError) {
        return "Invalid input: ${e.message}";
      }
      return "An error occurred while processing your request: $e";
    }
  }

  Future<String> generateResponse(
      String apiKey, String modelName, String prompt) async {
    final sanitizedPrompt = _sanitizePrompt(prompt);
    try {
      return await compute(_generateResponseInBackground, {
        'apiKey': apiKey,
        'modelName': modelName,
        'prompt': sanitizedPrompt,
      });
    } catch (e) {
      return "An error occurred while initiating the response process: $e";
    }
  }
}
