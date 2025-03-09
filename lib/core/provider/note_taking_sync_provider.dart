import 'package:flutter/material.dart';
import 'package:msbridge/core/services/note_taking_sync.dart';

class NoteTakingSyncProvider with ChangeNotifier {
  final SyncService _syncService = SyncService();
  bool _isSyncing = false;
  String? _errorMessage;

  bool get isSyncing => _isSyncing;
  String? get errorMessage => _errorMessage;

  Future<void> syncNotes() async {
    _isSyncing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _syncService.syncLocalNotesToFirebase();
      _isSyncing = false;
      notifyListeners();
    } catch (e) {
      _isSyncing = false;
      _errorMessage = "Sync failed: ${e.toString()}";
      notifyListeners();
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }
}
