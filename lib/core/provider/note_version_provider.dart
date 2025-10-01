// Flutter imports:
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_bugfender/flutter_bugfender.dart';

// Project imports:
import 'package:msbridge/core/database/note_taking/note_version.dart';
import 'package:msbridge/core/repo/note_taking_actions_repo.dart';
import 'package:msbridge/core/repo/note_version_repo.dart';
import 'package:msbridge/core/services/sync/version_sync_service.dart';

class NoteVersionProvider with ChangeNotifier {
  List<NoteVersion> _versions = [];
  bool _isLoading = false;
  String? _error;
  String? _currentNoteId;

  List<NoteVersion> get versions => _versions;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get currentNoteId => _currentNoteId;

  Future<void> loadVersions(String noteId) async {
    if (_currentNoteId == noteId && _versions.isNotEmpty) {
      return; // Already loaded
    }

    _setLoading(true);
    _error = null;
    _currentNoteId = noteId;

    try {
      final versions = await NoteVersionRepo.getNoteVersions(noteId);
      _versions = versions;
      _error = null;
    } catch (e) {
      _error = 'Failed to load versions: $e';
      _versions = [];
      FlutterBugfender.sendCrash(
          'Failed to load versions: $e', StackTrace.current.toString());
      FlutterBugfender.error(
        'Failed to load versions: $e',
      );
    } finally {
      _setLoading(false);
    }
  }

  Future<void> createVersion({
    required String noteId,
    required String noteTitle,
    required String noteContent,
    required List<String> tags,
    required String userId,
    required int versionNumber,
    String changeDescription = '',
  }) async {
    try {
      await NoteVersionRepo.createVersion(
        noteId: noteId,
        noteTitle: noteTitle,
        noteContent: noteContent,
        tags: tags,
        userId: userId,
        versionNumber: versionNumber,
        changeDescription: changeDescription,
      );

      // Reload versions if this is for the current note
      if (_currentNoteId == noteId) {
        await loadVersions(noteId);
      }
    } catch (e) {
      _error = 'Failed to create version: $e';
      FlutterBugfender.sendCrash(
          'Failed to create version: $e', StackTrace.current.toString());
      FlutterBugfender.error(
        'Failed to create version: $e',
      );
      notifyListeners();
    }
  }

  Future<void> deleteOldVersions(String noteId, int keepCount) async {
    try {
      await NoteVersionRepo.deleteOldVersions(noteId, keepCount);

      // Reload versions if this is for the current note
      if (_currentNoteId == noteId) {
        await loadVersions(noteId);
      }
    } catch (e) {
      _error = 'Failed to delete old versions: $e';
      FlutterBugfender.sendCrash(
          'Failed to delete old versions: $e', StackTrace.current.toString());
      FlutterBugfender.error(
        'Failed to delete old versions: $e',
      );
      notifyListeners();
    }
  }

  Future<void> deleteAllVersionsForNote(String noteId) async {
    try {
      await NoteVersionRepo.deleteAllVersionsForNote(noteId);

      // Clear versions if this is for the current note
      if (_currentNoteId == noteId) {
        _versions = [];
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to delete all versions: $e';
      FlutterBugfender.sendCrash(
          'Failed to delete all versions: $e', StackTrace.current.toString());
      FlutterBugfender.error(
        'Failed to delete all versions: $e',
      );
      notifyListeners();
    }
  }

  Future<int> getVersionCount(String noteId) async {
    try {
      return await NoteVersionRepo.getVersionCount(noteId);
    } catch (e) {
      _error = 'Failed to get version count: $e';
      FlutterBugfender.sendCrash(
          'Failed to get version count: $e', StackTrace.current.toString());
      FlutterBugfender.error(
        'Failed to get version count: $e',
      );
      notifyListeners();
      return 0;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearVersions() {
    _versions = [];
    _currentNoteId = null;
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  bool hasVersions() {
    return _versions.isNotEmpty;
  }

  int get versionCount => _versions.length;

  NoteVersion? getLatestVersion() {
    return _versions.isNotEmpty ? _versions.first : null;
  }

  NoteVersion? getVersionByNumber(int versionNumber) {
    try {
      return _versions.firstWhere(
        (version) => version.versionNumber == versionNumber,
      );
    } catch (e) {
      return null;
    }
  }

  Future<void> clearAllVersions() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await NoteVersionRepo.clearAllVersions();
      _versions.clear();
      _currentNoteId = null;
    } catch (e) {
      _error = 'Error clearing all versions: $e';
      FlutterBugfender.sendCrash(
          'Error clearing all versions: $e', StackTrace.current.toString());
      FlutterBugfender.error(
        'Error clearing all versions: $e',
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Restore a note from a specific version
  Future<bool> restoreNoteFromVersion(
      NoteVersion version, String userId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final result = await NoteTakingActions.restoreNoteFromVersion(
        versionToRestore: version,
        userId: userId,
      );

      if (result.success) {
        // Reload versions for the current note
        if (_currentNoteId != null) {
          await loadVersions(_currentNoteId!);
        }
        return true;
      } else {
        _error = result.message;
        return false;
      }
    } catch (e) {
      _error = 'Error restoring note: $e';
      FlutterBugfender.sendCrash(
          'Error restoring note: $e', StackTrace.current.toString());
      FlutterBugfender.error(
        'Error restoring note: $e',
      );
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Export version data for download
  Map<String, dynamic> exportVersionData(NoteVersion version) {
    return NoteVersionRepo.exportVersionData(version);
  }

  /// Get version count for a specific note
  Future<int> getVersionCountForNote(String noteId) async {
    try {
      return await NoteVersionRepo.getVersionCount(noteId);
    } catch (e) {
      _error = 'Error getting version count: $e';
      FlutterBugfender.sendCrash(
          'Error getting version count: $e', StackTrace.current.toString());
      FlutterBugfender.error(
        'Error getting version count: $e',
      );
      return 0;
    }
  }

  /// Clean up old versions based on max versions setting
  Future<bool> cleanupOldVersions(int maxVersionsToKeep) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final result =
          await NoteVersionRepo.cleanupOldVersions(maxVersionsToKeep);

      if (result['success'] == true) {
        // Reload versions if we have a current note
        if (_currentNoteId != null) {
          await loadVersions(_currentNoteId!);
        }
        return true;
      } else {
        _error = result['message'] ?? 'Unknown error during cleanup';
        return false;
      }
    } catch (e) {
      _error = 'Error cleaning up versions: $e';
      FlutterBugfender.sendCrash(
          'Error cleaning up versions: $e', StackTrace.current.toString());
      FlutterBugfender.error(
        'Error cleaning up versions: $e',
      );
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get total version count across all notes
  Future<int> getTotalVersionCount() async {
    try {
      return await NoteVersionRepo.getTotalVersionCount();
    } catch (e) {
      _error = 'Error getting total version count: $e';
      FlutterBugfender.sendCrash('Error getting total version count: $e',
          StackTrace.current.toString());
      FlutterBugfender.error(
        'Error getting total version count: $e',
      );
      return 0;
    }
  }

  /// Get storage usage information
  Future<Map<String, dynamic>> getStorageInfo() async {
    try {
      return await NoteVersionRepo.getStorageInfo();
    } catch (e) {
      _error = 'Error getting storage info: $e';
      FlutterBugfender.sendCrash(
          'Error getting storage info: $e', StackTrace.current.toString());
      FlutterBugfender.error(
        'Error getting storage info: $e',
      );
      return {};
    }
  }

  /// Get version sync status
  Future<Map<String, dynamic>> getVersionSyncStatus() async {
    try {
      final versionSyncService = VersionSyncService();
      return await versionSyncService.getVersionSyncStatus();
    } catch (e) {
      _error = 'Error getting sync status: $e';
      FlutterBugfender.sendCrash(
          'Error getting sync status: $e', StackTrace.current.toString());
      FlutterBugfender.error(
        'Error getting sync status: $e',
      );
      return {
        'enabled': false,
        'message': 'Error: $e',
        'localVersions': 0,
        'cloudVersions': 0,
      };
    }
  }
}
