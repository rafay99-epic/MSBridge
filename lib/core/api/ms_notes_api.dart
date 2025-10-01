// Dart imports:
import 'dart:convert';
import 'dart:io';

// Package imports:
import 'package:flutter_bugfender/flutter_bugfender.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;

// Project imports:
import 'package:msbridge/config/config.dart';
import '../database/note_reading/notes_model.dart';

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
        FlutterBugfender.sendCrash(
            'MSNotes: Invalid URL format: $apiUrl.  Error: $e',
            StackTrace.current.toString());
        FlutterBugfender.error(
          'MSNotes: Invalid URL format: $apiUrl.  Error: $e',
        );
        throw ApiException('Invalid URL format: $apiUrl.  Error: $e');
      }

      http.Response response;
      try {
        response = await http.get(uri);
      } on SocketException catch (e) {
        FlutterBugfender.sendCrash(
            'MSNotes: Failed to connect to the server. Please check your internet connection. Error: $e',
            StackTrace.current.toString());
        FlutterBugfender.error(
          'MSNotes: Failed to connect to the server. Please check your internet connection. Error: $e',
        );
        throw ApiException(
            'Failed to connect to the server. Please check your internet connection. Error: $e');
      } on HttpException catch (e) {
        FlutterBugfender.sendCrash(
            'MSNotes: HTTP error occurred while connecting to the server. Error: $e',
            StackTrace.current.toString());
        FlutterBugfender.error(
          'MSNotes: HTTP error occurred while connecting to the server. Error: $e',
        );
        throw ApiException(
            'HTTP error occurred while connecting to the server. Error: $e');
      } catch (e) {
        FlutterBugfender.sendCrash(
            'MSNotes: An unexpected error occurred while connecting to the server. Error: $e',
            StackTrace.current.toString());
        FlutterBugfender.error(
          'MSNotes: An unexpected error occurred while connecting to the server. Error: $e',
        );
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
            FlutterBugfender.sendCrash('MSNotes: Error clearing Hive box: $e',
                StackTrace.current.toString());
            FlutterBugfender.error(
              'MSNotes: Error clearing Hive box: $e',
            );
            throw ApiException('Error clearing Hive box: $e');
          }
        }

        for (var item in jsonData) {
          // Get markdown content from the 'body' field instead of rendered HTML
          String bodyText = (item['body'] as String?) ?? '';

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
            FlutterBugfender.sendCrash(
                'MSNotes: Error putting note with ID ${note.id} into Hive box: $e',
                StackTrace.current.toString());
            FlutterBugfender.error(
              'MSNotes: Error putting note with ID ${note.id} into Hive box: $e',
            );
            throw ApiException(
                'Error putting note with ID ${note.id} into Hive box: $e');
          }
        }
      } else {
        FlutterBugfender.sendCrash(
            'MSNotes: Failed to fetch data: Status ${response.statusCode}',
            StackTrace.current.toString());
        FlutterBugfender.error(
          'MSNotes: Failed to fetch data: Status ${response.statusCode}',
        );
        throw ApiException(
            'Failed to fetch data: Status ${response.statusCode}');
      }
    } catch (e) {
      FlutterBugfender.sendCrash(
          'MSNotes: Unexpected error: $e', StackTrace.current.toString());
      FlutterBugfender.error(
        'MSNotes: Unexpected error: $e',
      );
      if (e is ApiException) {
        rethrow;
      } else {
        FlutterBugfender.sendCrash('MSNotes: Unexpected error: ${e.toString()}',
            StackTrace.current.toString());
        FlutterBugfender.error(
          'MSNotes: Unexpected error: ${e.toString()}',
        );
        throw ApiException('Unexpected Error: ${e.toString()}');
      }
    }
  }
}
