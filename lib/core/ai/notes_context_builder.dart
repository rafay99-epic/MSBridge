import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:msbridge/core/database/note_taking/note_taking.dart';
import 'package:msbridge/core/database/note_reading/notes_model.dart';

class NotesContextBuilder {
  static Future<String> buildJson({
    bool includePersonal = true,
    bool includeMsNotes = true,
    int maxCharsPerNote = 1200,
    int maxTotalChars = 160000,
  }) async {
    final Map<String, dynamic> root = {
      'version': '1.0',
      'generatedAt': DateTime.now().toIso8601String(),
      'personal': [],
      'msNotes': [],
    };

    int budget = maxTotalChars;

    if (includePersonal) {
      final box = await Hive.openBox<NoteTakingModel>('notes_taking');
      final items = box.values.toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      for (final n in items) {
        if (budget <= 0) break;
        final text = _safePlain(n.noteContent);
        final clipped = text.length > maxCharsPerNote ? text.substring(0, maxCharsPerNote) : text;
        final obj = {
          'id': n.noteId ?? '',
          'title': n.noteTitle,
          'updatedAt': n.updatedAt.toIso8601String(),
          'tags': n.tags,
          'content': clipped,
        };
        final size = clipped.length + n.noteTitle.length + 64;
        if (budget - size < 0) break;
        budget -= size;
        (root['personal'] as List).add(obj);
      }
    }

    if (includeMsNotes) {
      final box = await Hive.openBox<MSNote>('notesBox');
      final items = box.values.toList();
      for (final n in items) {
        if (budget <= 0) break;
        final content = (n.body ?? '').trim();
        final clipped = content.length > maxCharsPerNote ? content.substring(0, maxCharsPerNote) : content;
        final obj = {
          'id': n.id,
          'title': n.lectureTitle,
          'subject': n.subject,
          'updatedAt': n.pubDate,
          'content': clipped,
        };
        final size = clipped.length + n.lectureTitle.length + 64;
        if (budget - size < 0) break;
        budget -= size;
        (root['msNotes'] as List).add(obj);
      }
    }

    return const JsonEncoder.withIndent('  ').convert(root);
  }

  static String _safePlain(String content) {
    // Try parse Quill delta -> plain; fallback to raw
    try {
      final dynamic json = jsonDecode(content);
      if (json is List) {
        return json.map((op) => op is Map && op['insert'] is String ? op['insert'] as String : '').join('');
      }
      if (json is Map && json['ops'] is List) {
        final List ops = json['ops'];
        return ops.map((op) => op is Map && op['insert'] is String ? op['insert'] as String : '').join('');
      }
    } catch (_) {}
    return content;
  }
}
