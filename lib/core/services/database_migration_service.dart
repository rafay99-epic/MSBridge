import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_bugfender/flutter_bugfender.dart';

class DatabaseMigrationService {
  static const List<String> _boxNames = [
    'notesBox',
    'notes',
    'deleted_notes',
    'note_versions',
    'chat_history',
    'note_templates',
    'voice_notes',
  ];

  /// Safely opens a Hive box with error handling and automatic recovery
  static Future<void> safeOpenBox<T>(String boxName) async {
    try {
      await Hive.openBox<T>(boxName);
      FlutterBugfender.log('Successfully opened Hive box: $boxName');
    } catch (e) {
      if (_isCorruptedDatabaseError(e)) {
        FlutterBugfender.log(
            'Detected corrupted Hive box: $boxName - Error: $e');
        await _resetCorruptedBox<T>(boxName);
      } else {
        FlutterBugfender.sendCrash(
            'Unexpected error opening Hive box $boxName: $e',
            StackTrace.current.toString());
        rethrow;
      }
    }
  }

  /// Checks if the error indicates a corrupted database
  static bool _isCorruptedDatabaseError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('unknown typeid') ||
        errorString.contains('cannot read') ||
        errorString.contains('typeid: 33') ||
        errorString.contains('hiveerror');
  }

  /// Resets a corrupted Hive box by deleting and recreating it
  static Future<void> _resetCorruptedBox<T>(String boxName) async {
    try {
      FlutterBugfender.log('Attempting to reset corrupted Hive box: $boxName');

      // Close the box if it's open
      if (Hive.isBoxOpen(boxName)) {
        await Hive.box<T>(boxName).close();
      }

      // Delete the corrupted box from disk
      await Hive.deleteBoxFromDisk(boxName);

      // Recreate the box
      await Hive.openBox<T>(boxName);

      FlutterBugfender.log('Successfully reset Hive box: $boxName');
    } catch (resetError) {
      FlutterBugfender.sendCrash(
          'Failed to reset Hive box $boxName: $resetError',
          StackTrace.current.toString());
      rethrow;
    }
  }

  /// Performs a complete database reset (use with caution)
  static Future<void> resetAllBoxes() async {
    try {
      FlutterBugfender.log('Performing complete database reset');

      for (final boxName in _boxNames) {
        if (Hive.isBoxOpen(boxName)) {
          await Hive.box(boxName).close();
        }
        await Hive.deleteBoxFromDisk(boxName);
      }

      FlutterBugfender.log('Successfully reset all Hive boxes');
    } catch (e) {
      FlutterBugfender.sendCrash(
          'Failed to reset all Hive boxes: $e', StackTrace.current.toString());
      rethrow;
    }
  }

  /// Checks if any boxes are corrupted and need reset
  static Future<bool> hasCorruptedBoxes() async {
    for (final boxName in _boxNames) {
      try {
        if (!Hive.isBoxOpen(boxName)) {
          await Hive.openBox(boxName);
        }
      } catch (e) {
        if (_isCorruptedDatabaseError(e)) {
          return true;
        }
      }
    }
    return false;
  }
}
