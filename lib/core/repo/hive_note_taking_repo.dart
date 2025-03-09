import 'package:hive_flutter/hive_flutter.dart';
import 'package:msbridge/core/database/note_taking/note_taking.dart';
import 'package:flutter/foundation.dart';

class HiveNoteTakingRepo {
  static const String _boxName = 'notes';

  static Box<NoteTakingModel>? _box;

  static Future<Box<NoteTakingModel>> getBox() async {
    if (_box == null || !_box!.isOpen) {
      try {
        _box = await Hive.openBox<NoteTakingModel>(_boxName);
      } catch (e) {
        throw Exception('⚠️ Error opening Hive box "$_boxName": $e');
      }
    }
    return _box!;
  }

  static Future<void> addNote(NoteTakingModel note) async {
    try {
      var box = await getBox();
      await box.add(note);
    } catch (e) {
      throw Exception('⚠️ Error adding note to Hive box "$_boxName": $e');
    }
  }

  static Future<void> updateNote(NoteTakingModel note) async {
    try {
      await note.save();
    } catch (e) {
      throw Exception('⚠️ Error updating note in Hive box "$_boxName": $e');
    }
  }

  static Future<void> deleteNote(NoteTakingModel note) async {
    try {
      await note.delete();
    } catch (e) {
      throw Exception('⚠️ Error deleting note from Hive box "$_boxName": $e');
    }
  }

  static Future<ValueListenable<Box<NoteTakingModel>>>
      getNotesListenable() async {
    try {
      final box = await getBox();
      return box.listenable();
    } catch (e) {
      throw Exception('⚠️ Error getting notes from Hive box "$_boxName": $e');
    }
  }

  static Future<List<NoteTakingModel>> getNotes() async {
    try {
      var box = await getBox();
      return box.values.toList();
    } catch (e) {
      throw Exception('⚠️ Error getting notes from Hive box "$_boxName": $e');
    }
  }

  static Future<bool> isBoxEmpty() async {
    try {
      final box = await getBox();
      return box.isEmpty;
    } catch (e) {
      throw Exception('⚠️ Error checking if Hive box "$_boxName" is empty: $e');
    }
  }

  static Future<ValueListenable<Box<NoteTakingModel>>>
      watchNotesListenable() async {
    try {
      return await getNotesListenable();
    } catch (e) {
      throw Exception(
          '⚠️ Error getting ValueListenable for Hive box "$_boxName": $e');
    }
  }
}
