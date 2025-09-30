// Flutter imports:
import 'package:flutter/foundation.dart';

// Package imports:
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:hive_flutter/hive_flutter.dart';

// Project imports:
import 'package:msbridge/core/database/note_taking/note_taking.dart';
import 'package:msbridge/core/repo/note_version_repo.dart';

class HiveNoteTakingRepo {
  static const String _boxName = 'notes';
  static const String _deletedBoxName = 'deleted_notes';
  static Box<NoteTakingModel>? _box;
  static Box<NoteTakingModel>? _deletedBox;

  HiveNoteTakingRepo._();

  static final HiveNoteTakingRepo _instance = HiveNoteTakingRepo._();

  factory HiveNoteTakingRepo() => _instance;

  static Future<Box<NoteTakingModel>> getBox() async {
    if (_box == null || !_box!.isOpen) {
      try {
        _box = await Hive.openBox<NoteTakingModel>(_boxName);
      } catch (e) {
        throw Exception('Error opening Hive box "$_boxName": $e');
      }
    }
    return _box!;
  }

  static Future<Box<NoteTakingModel>> getDeletedBox() async {
    if (_deletedBox == null || !_deletedBox!.isOpen) {
      try {
        _deletedBox = await Hive.openBox<NoteTakingModel>(_deletedBoxName);
      } catch (e) {
        FirebaseCrashlytics.instance.recordError(
          e,
          StackTrace.current,
          reason: 'Error opening Hive box "$_deletedBoxName": $e',
        );
        throw Exception('Error opening Hive box "$_deletedBoxName": $e');
      }
    }
    return _deletedBox!;
  }

  static Future<void> addNoteToDeletedBox(NoteTakingModel note) async {
    try {
      final deletedBox = await getDeletedBox();
      final deletedNote = NoteTakingModel(
        noteId: note.noteId,
        noteTitle: note.noteTitle,
        noteContent: note.noteContent,
        isSynced: note.isSynced,
        isDeleted: note.isDeleted,
        updatedAt: note.updatedAt,
        userId: note.userId,
      );
      await deletedBox.put(deletedNote.noteId!, deletedNote);
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(
        e,
        StackTrace.current,
        reason: 'Error adding note to deleted box and the expection is $e',
      );
      throw Exception('Error adding note to deleted box: $e');
    }
  }

  static Future<void> addNoteToMainBox(NoteTakingModel note) async {
    try {
      final box = await getBox();
      final restoredNote = NoteTakingModel(
        noteId: note.noteId,
        noteTitle: note.noteTitle,
        noteContent: note.noteContent,
        isSynced: note.isSynced,
        isDeleted: note.isDeleted,
        updatedAt: note.updatedAt,
        userId: note.userId,
      );

      await box.put(restoredNote.noteId!, restoredNote);
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(
        e,
        StackTrace.current,
        reason: 'Error adding note to main box and the expection is $e',
      );
      throw Exception('Error occured while restoring note: $e');
    }
  }

  static Future<void> addNote(NoteTakingModel note) async {
    try {
      final box = await getBox();
      await box.add(note);
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(
        e,
        StackTrace.current,
        reason:
            'Error adding note to Hive box "$_boxName" and the expection is $e',
      );
      throw Exception('Error adding note to Hive box "$_boxName": $e');
    }
  }

  static Future<void> updateNote(NoteTakingModel note) async {
    try {
      await note.save();
    } catch (e) {
      throw Exception('Error updating note in Hive box "$_boxName": $e');
    }
  }

  static Future<void> permantentlyDeleteNote(NoteTakingModel note) async {
    try {
      // Also delete all versions for this note
      if (note.noteId != null && note.noteId!.isNotEmpty) {
        await NoteVersionRepo.clearVersionsForNote(note.noteId!);
      }

      final deletedBox = await getDeletedBox();
      await deletedBox.delete(note.noteId!);
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(
        e,
        StackTrace.current,
        reason:
            'Error deleting note from Hive box "$_boxName" and the expection is $e',
      );
      throw Exception('Error deleting note from Hive box "$_boxName": $e');
    }
  }

  static Future<void> deleteNote(NoteTakingModel note) async {
    try {
      final box = await getBox();
      await addNoteToDeletedBox(note);

      for (int i = 0; i < box.length; i++) {
        if (box.getAt(i)?.noteId == note.noteId) {
          await box.deleteAt(i);
          break;
        }
      }
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(
        e,
        StackTrace.current,
        reason:
            'Error deleting note from Hive box "$_boxName" and the expection is $e',
      );
      throw Exception('Error deleting note from Hive box "$_boxName": $e');
    }
  }

  static Future<ValueListenable<Box<NoteTakingModel>>>
      getNotesListenable() async {
    try {
      final box = await getBox();
      return box.listenable();
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(
        e,
        StackTrace.current,
        reason:
            'Error getting notes from Hive box "$_boxName" and the expection is $e',
      );
      throw Exception('Error getting notes from Hive box "$_boxName": $e');
    }
  }

  static Future<List<NoteTakingModel>> getNotes() async {
    try {
      final box = await getBox();
      return box.values.toList();
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(
        e,
        StackTrace.current,
        reason:
            'Error getting notes from Hive box "$_boxName" and the expection is $e',
      );
      throw Exception('Error getting notes from Hive box "$_boxName": $e');
    }
  }

  static Future<bool> isBoxEmpty() async {
    try {
      final box = await getBox();
      return box.isEmpty;
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(
        e,
        StackTrace.current,
        reason:
            'Error checking if Hive box "$_boxName" is empty and the expection is $e',
      );
      throw Exception('Error checking if Hive box "$_boxName" is empty: $e');
    }
  }

  static Future<ValueListenable<Box<NoteTakingModel>>>
      watchNotesListenable() async {
    try {
      return await getNotesListenable();
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(
        e,
        StackTrace.current,
        reason:
            'Error getting ValueListenable for Hive box "$_boxName" and the expection is $e',
      );
      throw Exception(
          'Error getting ValueListenable for Hive box "$_boxName": $e');
    }
  }

  static Future<bool> clearBox() async {
    try {
      final box = await getBox();
      await box.clear();

      return await isBoxEmpty();
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(
        e,
        StackTrace.current,
        reason: 'Error clearing Hive box "$_boxName" and the expection is $e',
      );
      throw Exception('Error clearing Hive box "$_boxName": $e');
    }
  }
}
