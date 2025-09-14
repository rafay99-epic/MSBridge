import 'package:flutter_bugfender/flutter_bugfender.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:msbridge/core/database/voice_notes/voice_note_model.dart';

class VoiceNoteRepo {
  static const String _boxName = 'voice_notes';
  static Box<VoiceNoteModel>? _box;

  VoiceNoteRepo._();

  static final VoiceNoteRepo _instance = VoiceNoteRepo._();

  factory VoiceNoteRepo() => _instance;

  static Future<Box<VoiceNoteModel>> getBox() async {
    if (_box == null || !_box!.isOpen) {
      try {
        _box = await Hive.openBox<VoiceNoteModel>(_boxName);
      } catch (e) {
        throw Exception('Error opening Hive box "$_boxName": $e');
      }
    }
    return _box!;
  }

  static Future<void> addVoiceNote(VoiceNoteModel voiceNote) async {
    try {
      final box = await getBox();
      final id = voiceNote.voiceNoteId;
      if (id == null || id.isEmpty) {
        throw ArgumentError('voiceNoteId is required to add a voice note');
      }
      await box.put(id, voiceNote);
    } catch (e) {
      FlutterBugfender.sendIssue(
        e.toString(),
        StackTrace.current.toString(),
      );

      throw Exception('Error adding voice note to Hive box "$_boxName": $e');
    }
  }

  static Future<void> updateVoiceNote(VoiceNoteModel voiceNote) async {
    try {
      await voiceNote.save();
    } catch (e) {
      FlutterBugfender.sendIssue(
        e.toString(),
        StackTrace.current.toString(),
      );
      throw Exception('Error updating voice note in Hive box "$_boxName": $e');
    }
  }

  static Future<List<VoiceNoteModel>> getAllVoiceNotes() async {
    try {
      final box = await getBox();
      return box.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      FlutterBugfender.sendIssue(
        e.toString(),
        StackTrace.current.toString(),
      );
      throw Exception('Error getting all voice notes: $e');
    }
  }

  static Future<VoiceNoteModel?> getVoiceNoteById(String voiceNoteId) async {
    try {
      final box = await getBox();
      return box.get(voiceNoteId);
    } catch (e) {
      FlutterBugfender.sendIssue(
        e.toString(),
        StackTrace.current.toString(),
      );
      throw Exception('Error getting voice note by ID: $e');
    }
  }

  static Future<void> deleteVoiceNote(VoiceNoteModel voiceNote) async {
    try {
      final box = await getBox();
      dynamic actualKey;
      VoiceNoteModel? foundVoiceNote;
      if (box.containsKey(voiceNote.voiceNoteId)) {
        actualKey = voiceNote.voiceNoteId;
        foundVoiceNote = box.get(voiceNote.voiceNoteId);
      } else {
        for (final key in box.keys) {
          final note = box.get(key);
          if (note != null && note.voiceNoteId == voiceNote.voiceNoteId) {
            actualKey = key;
            foundVoiceNote = note;
            break;
          }
        }
      }

      if (foundVoiceNote != null && actualKey != null) {
        await box.delete(actualKey);

        final stillExists = box.get(actualKey) != null;

        if (stillExists) {
          throw Exception('Failed to delete voice note from database');
        }
      } else {
        throw Exception('Voice note not found in database');
      }
    } catch (e) {
      FlutterBugfender.sendIssue(
        e.toString(),
        StackTrace.current.toString(),
      );
      throw Exception('Error deleting voice note: $e');
    }
  }

  static Future<List<VoiceNoteModel>> searchVoiceNotes(String query) async {
    try {
      final box = await getBox();
      final allVoiceNotes = box.values.toList();

      if (query.isEmpty) {
        return allVoiceNotes
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }

      final filteredVoiceNotes = allVoiceNotes.where((voiceNote) {
        return voiceNote.voiceNoteTitle
                .toLowerCase()
                .contains(query.toLowerCase()) ||
            (voiceNote.description
                    ?.toLowerCase()
                    .contains(query.toLowerCase()) ??
                false) ||
            voiceNote.tags
                .any((tag) => tag.toLowerCase().contains(query.toLowerCase()));
      }).toList();

      return filteredVoiceNotes
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      FlutterBugfender.sendIssue(
        e.toString(),
        StackTrace.current.toString(),
      );
      throw Exception('Error searching voice notes: $e');
    }
  }

  static Future<List<VoiceNoteModel>> getVoiceNotesByUserId(
      String userId) async {
    try {
      final box = await getBox();
      return box.values
          .where((voiceNote) => voiceNote.userId == userId)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      FlutterBugfender.sendIssue(
        e.toString(),
        StackTrace.current.toString(),
      );
      throw Exception('Error getting voice notes by user ID: $e');
    }
  }

  static Future<List<VoiceNoteModel>> getUnsyncedVoiceNotes() async {
    try {
      final box = await getBox();
      return box.values.where((voiceNote) => !voiceNote.isSynced).toList();
    } catch (e) {
      FlutterBugfender.sendIssue(
        e.toString(),
        StackTrace.current.toString(),
      );
      throw Exception('Error getting unsynced voice notes: $e');
    }
  }

  static Future<void> clearAllVoiceNotes() async {
    try {
      final box = await getBox();
      await box.clear();
    } catch (e) {
      FlutterBugfender.sendIssue(
        e.toString(),
        StackTrace.current.toString(),
      );
      throw Exception('Error clearing all voice notes: $e');
    }
  }

  static Future<void> debugShowAllVoiceNotes() async {
    try {
      final box = await getBox();

      for (final key in box.keys) {
        final voiceNote = box.get(key);
        if (voiceNote != null) {}
      }
    } catch (e) {
      FlutterBugfender.sendIssue(
        e.toString(),
        StackTrace.current.toString(),
      );
      throw Exception('Error showing debug info: $e');
    }
  }
}
