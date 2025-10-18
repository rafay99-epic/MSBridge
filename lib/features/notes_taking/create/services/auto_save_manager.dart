// Dart imports:
import 'dart:async';
import 'dart:convert';

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_bugfender/flutter_bugfender.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:msbridge/core/background_process/create_note_background.dart';
import 'package:provider/provider.dart';

// Project imports:
import 'package:msbridge/config/feature_flag.dart';
import 'package:msbridge/core/database/note_taking/note_taking.dart';
import 'package:msbridge/core/provider/auto_save_note_provider.dart';
import 'package:msbridge/core/repo/note_taking_actions_repo.dart';
import 'package:msbridge/core/services/streak/streak_integration_service.dart';
import 'package:msbridge/widgets/snakbar.dart';

class AutoSaveManager {
  Timer? _autoSaveTimer;
  Timer? _debounceTimer;
  StreamSubscription? _docChangesSub;
  String _lastSavedContent = "";
  bool _isSaving = false;

  void startAutoSave(
    BuildContext context,
    QuillController controller,
    TextEditingController titleController,
    ValueNotifier<List<String>> tagsNotifier,
    ValueNotifier<String> currentFocusArea,
    ValueNotifier<bool> isSavingNotifier,
    ValueNotifier<bool> showCheckmarkNotifier,
    NoteTakingModel? currentNote,
    Function(NoteTakingModel?) onNoteUpdated,
  ) {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      final autoSaveProvider =
          Provider.of<AutoSaveProvider>(context, listen: false);

      if (!context.mounted || !autoSaveProvider.autoSaveEnabled) {
        timer.cancel();
        return;
      }

      String currentContent =
          jsonEncode(controller.document.toDelta().toJson());
      if (currentContent != _lastSavedContent) {
        _lastSavedContent = currentContent;
        _saveNote(
          context,
          controller,
          titleController,
          tagsNotifier,
          currentFocusArea,
          isSavingNotifier,
          showCheckmarkNotifier,
          currentNote,
          onNoteUpdated,
        );
      }
    });
  }

  void attachControllerListeners(
    QuillController controller,
    ValueNotifier<String> currentFocusArea,
    Function() saveNote,
  ) {
    // Debounced document changes for auto-save
    if (FeatureFlag.enableAutoSave) {
      _docChangesSub?.cancel();
      _docChangesSub = controller.document.changes.listen((event) {
        if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
        _debounceTimer = Timer(const Duration(seconds: 3), () {
          currentFocusArea.value = 'editor';
          saveNote();
        });
      });
    }
  }

  void addTagWithDebounce(
    String rawTag,
    ValueNotifier<List<String>> tagsNotifier,
    TextEditingController tagInputController,
    ValueNotifier<String> currentFocusArea,
    Function() saveNote,
  ) {
    final tag = rawTag.trim();
    if (tag.isEmpty) return;
    final current = List<String>.from(tagsNotifier.value);
    if (!current.contains(tag)) {
      current.add(tag);
      tagsNotifier.value = current;
      tagInputController.clear();

      if (FeatureFlag.enableAutoSave) {
        if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
        _debounceTimer = Timer(const Duration(seconds: 1), () {
          currentFocusArea.value = 'tags';
          saveNote();
        });
      }
    }
  }

  Future<void> _saveNote(
    BuildContext context,
    QuillController controller,
    TextEditingController titleController,
    ValueNotifier<List<String>> tagsNotifier,
    ValueNotifier<String> currentFocusArea,
    ValueNotifier<bool> isSavingNotifier,
    ValueNotifier<bool> showCheckmarkNotifier,
    NoteTakingModel? currentNote,
    Function(NoteTakingModel?) onNoteUpdated,
  ) async {
    if (_isSaving) return; // prevent overlapping saves
    _isSaving = true;
    final autoSaveProvider =
        Provider.of<AutoSaveProvider>(context, listen: false);
    if (!context.mounted || !autoSaveProvider.autoSaveEnabled) {
      _isSaving = false;
      return;
    }

    final title = titleController.text.trim();
    String content;

    isSavingNotifier.value = true;
    showCheckmarkNotifier.value = false;

    try {
      try {
        content = await encodeContent(controller.document.toDelta());
      } catch (e) {
        FlutterBugfender.sendCrash(
            'Failed to encode content: $e', StackTrace.current.toString());
        content = controller.document.toPlainText().trim();
      }
      if (title.isEmpty && content.isEmpty) {
        _isSaving = false;
        return;
      }

      SaveNoteResult result;
      if (currentNote != null) {
        result = await NoteTakingActions.updateNote(
          note: currentNote,
          title: title,
          content: content,
          isSynced: false,
          tags: tagsNotifier.value,
        );
      } else {
        result = await NoteTakingActions.saveNote(
          title: title,
          content: content,
          tags: tagsNotifier.value,
        );
        if (result.success && result.note != null) {
          onNoteUpdated(result.note);
          try {
            await StreakIntegrationService.onNoteCreated(context);
          } catch (e) {
            FlutterBugfender.sendCrash(
                'Streak update failed on note creation: $e',
                StackTrace.current.toString());
          }
        }
      }

      if (context.mounted) {
        isSavingNotifier.value = false;
        showCheckmarkNotifier.value = true;

        Future.delayed(const Duration(seconds: 1), () {
          if (context.mounted) {
            showCheckmarkNotifier.value = false;
          }
        });
      }
    } catch (e) {
      FlutterBugfender.sendCrash(
          'Failed to save note: $e', StackTrace.current.toString());
      if (context.mounted) {
        isSavingNotifier.value = false;
        showCheckmarkNotifier.value = false;
        CustomSnackBar.show(context, "Error saving note: $e", isSuccess: false);
      }
    }
    _isSaving = false;
  }

  void dispose() {
    _autoSaveTimer?.cancel();
    _debounceTimer?.cancel();
    _docChangesSub?.cancel();
  }
}
