import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/foundation.dart';

import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
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
    await FileSaver.instance.saveFile(
      name: 'msbridge-notes-${DateTime.now().millisecondsSinceEpoch}',
      ext: 'json',
      mimeType: MimeType.json,
      bytes: bytes,
    );
  }

  static Future<BackupReport> importFromFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json']);
    if (result == null || result.files.isEmpty) {
      return BackupReport(total: 0, inserted: 0, updated: 0, skipped: 0);
    }
    final file = result.files.first;
    Uint8List raw;
    if (file.bytes != null) {
      raw = file.bytes!;
    } else if (!kIsWeb && file.path != null) {
      raw = await File(file.path!).readAsBytes();
    } else {
      throw Exception('Unable to read selected file');
    }
    final content = utf8.decode(raw);
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
