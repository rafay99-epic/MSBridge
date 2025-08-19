import 'dart:convert';
import 'dart:io';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:path_provider/path_provider.dart';
import 'package:msbridge/core/database/note_taking/note_version.dart';

class VersionDownloadUtils {
  /// Download version data as a JSON file
  static Future<String> downloadVersionAsJson(NoteVersion version) async {
    try {
      Directory? downloadsDirectory;

      if (Platform.isAndroid) {
        final publicDownloads = Directory('/storage/emulated/0/Download');
        try {
          downloadsDirectory = publicDownloads;
        } catch (e) {
          FirebaseCrashlytics.instance.recordError(e, StackTrace.current,
              reason: 'Error getting public downloads directory');
          downloadsDirectory = null;
        }
      } else if (Platform.isIOS) {
        // For iOS, use app documents directory
        final appDir = await getApplicationDocumentsDirectory();
        final downloadsPath = '${appDir.path}/Downloads';
        downloadsDirectory = Directory(downloadsPath);
      }

      if (downloadsDirectory == null) {
        FirebaseCrashlytics.instance
            .log('Could not find the downloads directory');
        throw Exception('Could not find the downloads directory');
      }

      // Create downloads directory if it doesn't exist
      if (!await downloadsDirectory.exists()) {
        FirebaseCrashlytics.instance
            .log('Downloads directory does not exist, creating it');
        await downloadsDirectory.create(recursive: true);
      }

      // Create filename with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename =
          'MSBridge_Note_V${version.versionNumber}_$timestamp.json';
      final file = File('${downloadsDirectory.path}/$filename');
      FirebaseCrashlytics.instance.log('File path: ${file.path}');

      // Export version data
      final exportData = {
        'versionId': version.versionId,
        'noteId': version.noteId,
        'noteTitle': version.noteTitle,
        'noteContent': version.noteContent,
        'tags': version.tags,
        'createdAt': version.createdAt.toIso8601String(),
        'userId': version.userId,
        'changeDescription': version.changeDescription,
        'versionNumber': version.versionNumber,
        'changes': version.changes,
        'previousVersionId': version.previousVersionId,
        'exportedAt': DateTime.now().toIso8601String(),
        'exportFormat': 'MSBridge_Note_Version',
        'appVersion': '1.0.0',
      };

      // Write to file
      await file.writeAsString(jsonEncode(exportData), flush: true);
      FirebaseCrashlytics.instance.log('File written successfully');
      return file.path;
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(e, StackTrace.current,
          reason: 'Error downloading version');
      throw Exception('Error downloading version: $e');
    }
  }

  /// Import version data from a JSON file
  static Future<Map<String, dynamic>> importVersionFromJson(
      String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('File not found: $filePath');
      }

      final content = await file.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;

      // Validate the file format
      if (data['exportFormat'] != 'MSBridge_Note_Version') {
        throw Exception(
            'Invalid file format. This is not a MSBridge note version file.');
      }

      return data;
    } catch (e) {
      throw Exception('Error importing version: $e');
    }
  }

  /// Create a NoteVersion from imported data
  static NoteVersion createVersionFromImportedData(Map<String, dynamic> data) {
    return NoteVersion(
      versionId: data['versionId'] ?? '',
      noteId: data['noteId'] ?? '',
      noteTitle: data['noteTitle'] ?? '',
      noteContent: data['noteContent'] ?? '',
      tags: List<String>.from(data['tags'] ?? []),
      createdAt: DateTime.parse(data['createdAt']),
      userId: data['userId'] ?? '',
      changeDescription: data['changeDescription'] ?? '',
      versionNumber: data['versionNumber'] ?? 1,
      changes: List<String>.from(data['changes'] ?? []),
      previousVersionId: data['previousVersionId'] ?? '',
    );
  }

  /// Get download directory path
  static Future<String> getDownloadDirectory() async {
    Directory? downloadsDirectory;

    if (Platform.isAndroid) {
      downloadsDirectory = Directory('/storage/emulated/0/Download');
    } else if (Platform.isIOS) {
      final appDir = await getApplicationDocumentsDirectory();
      final downloadsPath = '${appDir.path}/Downloads';
      downloadsDirectory = Directory(downloadsPath);
    }

    if (downloadsDirectory == null) {
      throw Exception('Could not find the downloads directory');
    }

    return downloadsDirectory.path;
  }

  /// List all downloaded version files
  static Future<List<FileSystemEntity>> listDownloadedFiles() async {
    try {
      final directory = await getDownloadDirectory();
      final dir = Directory(directory);

      if (!await dir.exists()) {
        return [];
      }

      return dir
          .listSync()
          .where((entity) => entity is File && entity.path.endsWith('.json'))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Delete a downloaded version file
  static Future<bool> deleteDownloadedFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      return false;
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
}
