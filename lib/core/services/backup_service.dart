import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_selector/file_selector.dart' as fsel;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:msbridge/core/database/note_taking/note_taking.dart';
import 'package:msbridge/core/repo/hive_note_taking_repo.dart';
import 'package:msbridge/core/permissions/permission.dart';

class BackupReport {
  final int total;
  final int inserted;
  final int updated;
  final int skipped;
  BackupReport(
      {required this.total,
      required this.inserted,
      required this.updated,
      required this.skipped});
}

class BackupService {
  static const String backupVersion = '1.0.0';

  /// Export all notes to a JSON backup file
  static Future<String> exportAllNotes(BuildContext context) async {
    try {
      // Check and request storage permissions first
      bool hasPermission =
          await PermissionHandler.checkAndRequestFilePermission(context);
      if (!hasPermission) {
        throw Exception('Storage permission denied. Cannot create backup.');
      }

      // Get all notes from Hive
      final notes = await HiveNoteTakingRepo.getNotes();
      if (notes.isEmpty) {
        throw Exception('No notes found to backup');
      }

      // Convert notes to JSON
      final payload = notes.map((note) => note.toMap()).toList();
      final jsonString = const JsonEncoder.withIndent('  ').convert(payload);
      final bytes = Uint8List.fromList(utf8.encode(jsonString));

      // Generate filename with timestamp
      final timestamp = DateTime.now();
      final formattedDate =
          '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')}_${timestamp.hour.toString().padLeft(2, '0')}-${timestamp.minute.toString().padLeft(2, '0')}';
      final String fileName = 'msbridge-notes-backup-$formattedDate.json';

      // Save to Downloads folder with proper permissions
      final filePath =
          await _saveToDownloadsWithPermissions(fileName, bytes, context);

      // Log successful backup
      await FirebaseCrashlytics.instance.log(
        'Backup created successfully: $fileName',
      );

      return filePath;
    } catch (e) {
      await FirebaseCrashlytics.instance.recordError(
        e,
        null,
        reason: 'Failed to export notes',
        information: ['Method: exportAllNotes'],
      );
      throw Exception('Failed to export notes: $e');
    }
  }

  /// Save file to Downloads folder with proper permissions (following PDF exporter pattern)
  static Future<String> _saveToDownloadsWithPermissions(
      String fileName, Uint8List bytes, BuildContext context) async {
    try {
      await FirebaseCrashlytics.instance.log(
        'Saving backup with permissions: $fileName',
      );

      Directory? downloadsDirectory;
      if (Platform.isAndroid) {
        // Use the same approach as PDF exporter - direct Downloads folder access
        downloadsDirectory = Directory('/storage/emulated/0/Download');

        // Ensure directory exists
        if (!await downloadsDirectory.exists()) {
          await downloadsDirectory.create(recursive: true);
        }
      } else if (Platform.isIOS) {
        // For iOS, use app documents directory
        downloadsDirectory = await getApplicationDocumentsDirectory();
        final downloadsPath = '${downloadsDirectory.path}/Downloads';
        downloadsDirectory = Directory(downloadsPath);

        if (!await downloadsDirectory.exists()) {
          await downloadsDirectory.create(recursive: true);
        }
      }

      if (downloadsDirectory == null) {
        throw Exception('Could not find the downloads directory');
      }

      final file = File('${downloadsDirectory.path}/$fileName');
      await file.writeAsBytes(bytes);

      // Verify file was written
      if (await file.exists()) {
        await FirebaseCrashlytics.instance.log(
          'Backup saved successfully: ${file.path}',
        );
        return file.path;
      } else {
        throw Exception('File was not created successfully');
      }
    } catch (e) {
      await FirebaseCrashlytics.instance.recordError(
        e,
        null,
        reason: 'Failed to save backup with permissions',
        information: [
          'Method: _saveToDownloadsWithPermissions',
          'FileName: $fileName'
        ],
      );
      throw Exception('Failed to save backup: $e');
    }
  }

  /// Get detailed file location information for users
  static String getDetailedFileLocation(String filePath) {
    if (filePath.contains('/storage/')) {
      return 'Device Downloads folder';
    } else if (filePath.contains('/Documents/')) {
      return 'App Downloads folder';
    } else if (filePath.contains('/cache/')) {
      return 'App Cache folder';
    } else {
      return 'App folder';
    }
  }

  /// Get user-friendly path for display
  static String getUserFriendlyPath(String filePath) {
    if (filePath.contains('/Download/') || filePath.contains('/Downloads/')) {
      if (filePath.contains('/storage/')) {
        return 'Device Downloads folder';
      } else if (filePath.contains('/Documents/')) {
        return 'App Downloads folder';
      } else if (filePath.contains('/cache/')) {
        return 'App Cache folder';
      }
      return 'Downloads folder';
    } else if (filePath.contains('/DCIM/')) {
      return 'Camera folder';
    } else if (filePath.contains('/Pictures/')) {
      return 'Pictures folder';
    } else if (filePath.contains('/Documents/')) {
      return 'App Documents folder';
    } else {
      return 'App folder';
    }
  }

  /// Import notes from a backup file
  static Future<BackupReport> importFromFile() async {
    Uint8List raw;

    try {
      // Try file_picker first
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return BackupReport(total: 0, inserted: 0, updated: 0, skipped: 0);
      }

      final file = result.files.first;
      if (file.bytes != null) {
        raw = file.bytes!;
      } else if (!kIsWeb && file.path != null) {
        raw = await File(file.path!).readAsBytes();
      } else {
        throw Exception('Unable to read selected file');
      }
    } catch (_) {
      try {
        // Fallback to file_selector
        const typeGroup = fsel.XTypeGroup(label: 'json', extensions: ['json']);
        final fsel.XFile? xfile =
            await fsel.openFile(acceptedTypeGroups: [typeGroup]);
        if (xfile == null) {
          return BackupReport(total: 0, inserted: 0, updated: 0, skipped: 0);
        }
        raw = await xfile.readAsBytes();
      } catch (_) {
        // Final fallback: try to read latest local backup
        final content = await _readLatestLocalBackup();
        if (content == null) {
          await FirebaseCrashlytics.instance.recordError(
            Exception('All import methods failed'),
            null,
            reason: 'Failed to import backup file',
            information: ['Method: importFromFile', 'All fallbacks exhausted'],
          );
          rethrow;
        }
        return await importFromString(content);
      }
    }

    final content = utf8.decode(raw);
    return await importFromString(content);
  }

  /// Read the latest local backup file
  static Future<String?> _readLatestLocalBackup() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final d = Directory(dir.path);
      final files = await d
          .list()
          .where((e) =>
              e is File &&
              e.path.endsWith('.json') &&
              e.path.contains('msbridge-notes-backup-'))
          .toList();

      if (files.isEmpty) return null;

      files.sort((a, b) => FileStat.statSync(b.path)
          .modified
          .compareTo(FileStat.statSync(a.path).modified));
      final latest = files.first;
      return await File(latest.path).readAsString();
    } catch (_) {
      await FirebaseCrashlytics.instance.recordError(
        Exception('Failed to read latest local backup'),
        null,
        reason: 'Failed to read local backup file',
        information: ['Method: _readLatestLocalBackup'],
      );
      return null;
    }
  }

  /// Import notes from JSON string
  static Future<BackupReport> importFromString(String content) async {
    final data = jsonDecode(content) as Map<String, dynamic>;
    final List notes = (data['notes'] as List?) ?? [];

    final Box<NoteTakingModel> box = await HiveNoteTakingRepo.getBox();
    int inserted = 0, updated = 0, skipped = 0;

    for (final raw in notes) {
      final map = Map<String, dynamic>.from(raw as Map);
      final incoming = NoteTakingModel.fromMap(map);

      if (incoming.noteId == null || incoming.noteId!.isEmpty) {
        skipped++;
        continue;
      }

      // Find existing by noteId
      NoteTakingModel? existing;
      for (int i = 0; i < box.length; i++) {
        final item = box.getAt(i);
        if (item?.noteId == incoming.noteId) {
          existing = item;
          break;
        }
      }

      if (existing == null) {
        await box.put(incoming.noteId!, incoming);
        inserted++;
      } else {
        // Merge by updatedAt – keep newer
        if (incoming.updatedAt.isAfter(existing.updatedAt)) {
          existing
            ..noteTitle = incoming.noteTitle
            ..noteContent = incoming.noteContent
            ..tags = incoming.tags
            ..isSynced = false
            ..isDeleted = incoming.isDeleted
            ..updatedAt = incoming.updatedAt;
          await existing.save();
          updated++;
        } else {
          skipped++;
        }
      }
    }

    return BackupReport(
        total: notes.length,
        inserted: inserted,
        updated: updated,
        skipped: skipped);
  }
}
