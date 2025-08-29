import 'dart:convert';
import 'package:flutter_bugfender/flutter_bugfender.dart';
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
      try {
        final box = await Hive.openBox<NoteTakingModel>('notes');

        if (!box.isOpen) {
          await FlutterBugfender.error(
            'Personal notes box is not open. This may cause issues.',
          );
        }

        final items = box.values.toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

        if (items.isEmpty) {
          await FlutterBugfender.error(
            'Personal notes box is empty. No notes found for AI context.',
          );
        } else {
          await FlutterBugfender.error(
            'Found ${items.length} personal notes for AI context. Budget: $budget characters',
          );
        }

        for (final n in items) {
          if (budget <= 0) break;
          final text = _safePlain(n.noteContent);
          final clipped = text.length > maxCharsPerNote
              ? text.substring(0, maxCharsPerNote)
              : text;
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

        await FlutterBugfender.log(
          'Added ${(root['personal'] as List).length} personal notes to context. Remaining budget: $budget characters',
        );
      } catch (e) {
        await FlutterBugfender.error(
          'Failed to load personal notes for AI context: $e',
        );
        rethrow;
      }
    }

    if (includeMsNotes) {
      final box = await Hive.openBox<MSNote>('notesBox');
      try {
        final items = box.values.toList();

        if (items.isEmpty) {
          await FlutterBugfender.log(
            'MS Notes box is empty. No MS notes found for AI context.',
          );
        } else {
          await FlutterBugfender.log(
            'Found ${items.length} MS notes for AI context. Budget: $budget characters',
          );
        }

        for (final n in items) {
          if (budget <= 0) break;
          final content = (n.body ?? '').trim();
          final clipped = content.length > maxCharsPerNote
              ? content.substring(0, maxCharsPerNote)
              : content;
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

        await FlutterBugfender.log(
          'Added ${(root['msNotes'] as List).length} MS notes to context. Remaining budget: $budget characters',
        );
      } catch (e) {
        await FlutterBugfender.error(
          'Failed to load MS notes for AI context: $e',
        );
        rethrow;
      }
    }

    return const JsonEncoder.withIndent('  ').convert(root);
  }

  static String _safePlain(String content) {
    // Try parse Quill delta -> plain; fallback to raw
    try {
      final dynamic json = jsonDecode(content);
      if (json is List) {
        return json
            .map((op) => op is Map && op['insert'] is String
                ? op['insert'] as String
                : '')
            .join('');
      }
      if (json is Map && json['ops'] is List) {
        final List ops = json['ops'];
        return ops
            .map((op) => op is Map && op['insert'] is String
                ? op['insert'] as String
                : '')
            .join('');
      }
    } catch (e) {
      FlutterBugfender.error(
        'Failed to parse Quill delta: $e',
      );
    }
    return content;
  }
}
