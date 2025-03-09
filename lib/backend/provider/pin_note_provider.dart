import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NoteProvider with ChangeNotifier {
  SharedPreferences? _prefs;
  final Map<String, bool> _pinnedNotes = {};

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadPinnedNotes();
  }

  Future<void> _loadPinnedNotes() async {
    final prefs = _prefs;
    if (prefs == null) return;

    final keys = prefs.getKeys();
    for (var key in keys) {
      if (key.startsWith('pinned_')) {
        _pinnedNotes[key.substring(7)] = prefs.getBool(key) ?? false;
      }
    }
    notifyListeners();
  }

  Future<void> togglePin(String noteId) async {
    final isCurrentlyPinned = _pinnedNotes[noteId] ?? false;
    _pinnedNotes[noteId] = !isCurrentlyPinned;
    await _prefs?.setBool('pinned_$noteId', !isCurrentlyPinned);
    notifyListeners();
  }

  bool isNotePinned(String noteId) {
    return _pinnedNotes[noteId] ?? false;
  }
}
