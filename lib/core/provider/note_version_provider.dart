import 'package:flutter/material.dart';
import 'package:msbridge/core/database/note_taking/note_version.dart';
import 'package:msbridge/core/repo/note_version_repo.dart';

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
      notifyListeners();
    }
  }

  Future<int> getVersionCount(String noteId) async {
    try {
      return await NoteVersionRepo.getVersionCount(noteId);
    } catch (e) {
      _error = 'Failed to get version count: $e';
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
}
