import 'package:http/http.dart' as http;
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
  static const String apiUrl = 'https://www.rafay99.com/api/ms_notes';

  static Future<void> fetchAndSaveNotes() async {
    try {
      var response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        List<dynamic> jsonData = jsonDecode(response.body);
        var box = Hive.box<MSNote>('notesBox');

        if (box.isNotEmpty) {
          await box.clear();
        }

        for (var item in jsonData) {
          MSNote note = MSNote(
            id: item['id'] ?? 0,
            lectureTitle: item['data']['lecture_title'] ?? '',
            lectureDescription: item['data']['lecture_description'] ?? '',
            pubDate: item['data']['pubDate'] ?? '',
            lectureDraft: item['data']['lectureDraft'] ?? false,
            lectureNumber: item['data']['lectureNumber'] ?? 0,
            subject: item['data']['subject'] ?? '',
            body: item['data']['body'] ?? '',
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
