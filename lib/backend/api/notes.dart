import 'package:http/http.dart' as http;
import 'package:msbridge/config/config.dart';
import 'dart:convert';
import '../models/notes_model.dart';
import 'package:hive/hive.dart';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}

class ApiService {
  static const String apiUrl = APIConfig.notesApiEndpoint;

  static Future<void> fetchAndSaveNotes() async {
    try {
      var response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        List<Map<String, dynamic>> jsonData =
            (jsonDecode(response.body) as List).cast<Map<String, dynamic>>();
        var box = Hive.box<MSNote>('notesBox');

        if (box.isNotEmpty) {
          await box.clear();
        }

        for (var item in jsonData) {
          String bodyText =
              (item['rendered']?['html'] as String?) ?? ''; // Use null safety

          MSNote note = MSNote(
            id: item['id'] ?? 0,
            lectureTitle: item['data']['lecture_title'] ?? '',
            lectureDescription: item['data']['lecture_description'] ?? '',
            pubDate: item['data']['pubDate'] ?? '',
            lectureDraft: item['data']['lectureDraft'] ?? false,
            lectureNumber: item['data']['lectureNumber'] ?? 0,
            subject: item['data']['subject'] ?? '',
            body: bodyText,
          );
          await box.put(note.id, note);
        }
      } else {
        throw ApiException(
            'Failed to fetch data: Status ${response.statusCode}');
      }
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      } else {
        throw ApiException('Unexpected Error: ${e.toString()}');
      }
    }
  }
}
