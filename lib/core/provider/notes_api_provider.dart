// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_bugfender/flutter_bugfender.dart';
import 'package:hive/hive.dart';

// Project imports:
import 'package:msbridge/core/api/ms_notes_api.dart';
import '../database/note_reading/notes_model.dart';

class LectureNotesProvider with ChangeNotifier {
  List<MSNote> _notes = [];
  bool _isLoading = false;
  String _errorMessage = '';

  List<MSNote> get notes => _notes;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  Future<void> fetchNotes() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      await ApiService.fetchAndSaveNotes();
      var box = Hive.box<MSNote>('notesBox');
      _notes = box.values.toList();
    } catch (e) {
      FlutterBugfender.sendCrash(
          'Failed to fetch notes: $e', StackTrace.current.toString());
      FlutterBugfender.error(
        'Failed to fetch notes: $e',
      );
      if (e is ApiException) {
        _errorMessage = e.message;
      } else {
        _errorMessage = 'Something went wrong!';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
