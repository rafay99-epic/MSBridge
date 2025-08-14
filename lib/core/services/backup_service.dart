import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/foundation.dart';

import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:downloads_path_provider_28/downloads_path_provider_28.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_selector/file_selector.dart' as fsel;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:msbridge/core/database/note_taking/note_taking.dart';
import 'package:msbridge/core/repo/hive_note_taking_repo.dart';

class BackupReport {
  final int total;
  final int inserted;
  final int updated;
  final int skipped;
  BackupReport({required this.total, required this.inserted, required this.updated, required this.skipped});
}

class BackupService {
  static const String backupVersion = '1.0.0';

  static Future<void> exportAllNotes() async {
    final notes = await HiveNoteTakingRepo.getNotes();
    final deletedBox = await HiveNoteTakingRepo.getDeletedBox();
    final deleted = deletedBox.values.toList();

    final payload = {
      'version': backupVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'notes': notes.map((n) => n.toMap()).toList(),
      'deletedNotes': deleted.map((n) => n.toMap()).toList(),
    };

    final bytes = Uint8List.fromList(utf8.encode(const JsonEncoder.withIndent('  ').convert(payload)));
    final String baseName = 'msbridge-notes-${DateTime.now().millisecondsSinceEpoch}';

    // On Android API 28+, write directly to Downloads. Else attempt FileSaver dialog.
    if (!kIsWeb && Platform.isAndroid) {
      try {
        final downloadsDir = await DownloadsPathProvider.downloadsDirectory;
        if (downloadsDir != null) {
          final filePath = '${downloadsDir.path}/$baseName.json';
          final file = File(filePath);
          await file.writeAsBytes(bytes, flush: true);
          return;
        }
      } catch (_) {}
    }

    try {
      await FileSaver.instance.saveFile(
        name: baseName,
        ext: 'json',
        mimeType: MimeType.json,
        bytes: bytes,
      );
    } catch (_) {
      // Fallback: write to app directory and present share sheet
      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/$baseName.json';
      final file = File(filePath);
      await file.writeAsBytes(bytes, flush: true);
      await Share.shareXFiles([XFile(filePath)], subject: 'MSBridge Notes Backup');
    }
  }

  static Future<BackupReport> importFromFile() async {
    Uint8List raw;
    // Try file_picker first; if plugin missing, fall back to file_selector
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json']);
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
        final typeGroup = const fsel.XTypeGroup(label: 'json', extensions: ['json']);
        final fsel.XFile? xfile = await fsel.openFile(acceptedTypeGroups: [typeGroup]);
        if (xfile == null) {
          return BackupReport(total: 0, inserted: 0, updated: 0, skipped: 0);
        }
        raw = await xfile.readAsBytes();
      } catch (_) {
        // Fallback 2: try the app documents directory for last backup we created
        final content = await _readLatestLocalBackup();
        if (content == null) {
          rethrow;
        }
        return await importFromString(content);
      }
    }
    final content = utf8.decode(raw);
    return await importFromString(content);
  }

  static Future<String?> _readLatestLocalBackup() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final d = Directory(dir.path);
      final files = await d
          .list()
          .where((e) => e is File && e.path.endsWith('.json') && e.path.contains('msbridge-notes-'))
          .toList();
      if (files.isEmpty) return null;
      files.sort((a, b) => FileStat.statSync(b.path).modified.compareTo(FileStat.statSync(a.path).modified));
      final latest = files.first as FileSystemEntity;
      return await File(latest.path).readAsString();
    } catch (_) {
      return null;
    }
  }

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

    return BackupReport(total: notes.length, inserted: inserted, updated: updated, skipped: skipped);
  }
}
