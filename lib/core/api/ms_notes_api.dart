import 'package:http/http.dart' as http;
import 'package:msbridge/config/config.dart';
import 'dart:convert';
import '../database/note_reading/notes_model.dart';
import 'package:hive/hive.dart';
import 'dart:io';

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
      Uri uri;
      try {
        uri = Uri.parse(apiUrl);
      } catch (e) {
        throw ApiException('Invalid URL format: $apiUrl.  Error: $e');
      }

      http.Response response;
      try {
        response = await http.get(uri);
      } on SocketException catch (e) {
        throw ApiException(
            'Failed to connect to the server. Please check your internet connection. Error: $e');
      } on HttpException catch (e) {
        throw ApiException(
            'HTTP error occurred while connecting to the server. Error: $e');
      } catch (e) {
        throw ApiException(
            'An unexpected error occurred while connecting to the server. Error: $e');
      }

      if (response.statusCode == 200) {
        List<Map<String, dynamic>> jsonData =
            (jsonDecode(response.body) as List).cast<Map<String, dynamic>>();
        var box = Hive.box<MSNote>('notesBox');

        if (box.isNotEmpty) {
          try {
            await box.clear();
          } catch (e) {
            throw ApiException('Error clearing Hive box: $e');
          }
        }

        for (var item in jsonData) {
          String bodyText = (item['rendered']?['html'] as String?) ?? '';

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

          try {
            await box.put(note.id, note);
          } catch (e) {
            throw ApiException(
                'Error putting note with ID ${note.id} into Hive box: $e');
          }
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
