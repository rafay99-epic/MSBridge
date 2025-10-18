// Dart imports:
import 'dart:async';
import 'dart:convert';

// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Package imports:
import 'package:flutter_bugfender/flutter_bugfender.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:line_icons/line_icons.dart';

// Project imports:
import 'package:msbridge/core/background_process/create_note_background.dart';
import 'package:msbridge/core/database/note_taking/note_taking.dart';
import 'package:msbridge/core/repo/note_taking_actions_repo.dart';
import 'package:msbridge/core/services/streak/streak_integration_service.dart';
import 'package:msbridge/widgets/snakbar.dart';

class CoreNoteManager {
  static Future<void> manualSaveNote(
    BuildContext context,
    TextEditingController titleController,
    QuillController controller,
    ValueNotifier<List<String>> tagsNotifier,
    NoteTakingModel? currentNote,
    Function(NoteTakingModel?) onNoteUpdated,
  ) async {
    String title = titleController.text.trim();
    String content;

    try {
      content = await encodeContent(controller.document.toDelta());
    } catch (e) {
      FlutterBugfender.sendCrash(
          'Failed to encode content: $e', StackTrace.current.toString());
      FlutterBugfender.error('Failed to encode content: $e');
      content = controller.document.toPlainText().trim();
    }
    SaveNoteResult result;

    try {
      if (currentNote != null) {
        result = await NoteTakingActions.updateNote(
          note: currentNote,
          title: title,
          content: content,
          isSynced: false,
          tags: tagsNotifier.value,
        );
        if (result.success && context.mounted) {
          CustomSnackBar.show(context, result.message, isSuccess: true);
          Navigator.pop(context);
        }
      } else {
        result = await NoteTakingActions.saveNote(
          title: title,
          content: content,
          tags: tagsNotifier.value,
        );

        if (result.success) {
          onNoteUpdated(result.note ?? currentNote);
          if (!context.mounted) return;
          CustomSnackBar.show(context, result.message, isSuccess: true);

          // Update streak when note is created
          try {
            await StreakIntegrationService.onNoteCreated(context);
          } catch (e) {
            FlutterBugfender.sendCrash(
                'Streak update failed on note creation: $e',
                StackTrace.current.toString());
          }
          if (!context.mounted) return;
          Navigator.pop(context);
        }
      }
    } catch (e) {
      FlutterBugfender.sendCrash(
          'Failed to save note: $e', StackTrace.current.toString());
      if (!context.mounted) return;
      CustomSnackBar.show(context, "Error saving note: $e", isSuccess: false);
    }
  }

  static Future<void> pasteText(
    QuillController controller,
    BuildContext context,
  ) async {
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      if (clipboardData?.text != null && clipboardData!.text!.isNotEmpty) {
        final selection = controller.selection;
        if (selection.isValid) {
          controller.replaceText(
            selection.start,
            selection.end - selection.start,
            clipboardData.text!,
            null,
          );
        } else {
          controller.document.insert(0, clipboardData.text!);
        }
      }
    } catch (e) {
      FlutterBugfender.sendCrash(
          'Failed to paste text: $e', StackTrace.current.toString());
      if (context.mounted) {
        CustomSnackBar.show(context, 'Failed to paste text', isSuccess: false);
      }
    }
  }

  static Future<void> loadQuillContent(
    QuillController controller,
    String noteContent,
  ) async {
    try {
      final jsonResult = jsonDecode(noteContent);
      if (jsonResult is List) {
        controller.document = Document.fromJson(jsonResult);
      } else {
        controller.document = Document()..insert(0, noteContent);
      }
    } catch (e) {
      FlutterBugfender.sendCrash(
          'Failed to load content: $e', StackTrace.current.toString());
      controller.document = Document()..insert(0, noteContent);
    }
  }

  static void reinitializeController(
    QuillController controller,
    Document newDoc,
    Function(StreamSubscription?) onDocChangesSubCancel,
    Function(StreamSubscription) onDocChangesSubSet,
    Function() attachControllerListeners,
  ) {
    // Dispose old controller to avoid leaks
    onDocChangesSubCancel(null);
    controller.dispose();
    controller = QuillController(
      document: newDoc,
      selection: const TextSelection.collapsed(offset: 0),
    );
    attachControllerListeners();
  }

  static Widget buildSaveButton(BuildContext context, VoidCallback onPressed) {
    return IconButton(
      tooltip: 'Save',
      icon: const Icon(LineIcons.save, size: 22),
      onPressed: onPressed,
    );
  }

  static Widget buildPasteButton(BuildContext context, VoidCallback onPressed) {
    return IconButton(
      tooltip: 'Paste',
      icon: const Icon(Icons.paste, size: 22),
      onPressed: onPressed,
    );
  }

  static Widget buildReadButton(BuildContext context, VoidCallback onPressed) {
    return IconButton(
      tooltip: 'Read',
      icon: const Icon(LineIcons.eye, size: 22),
      onPressed: onPressed,
    );
  }

  static Widget buildMoreOptionsButton(
      BuildContext context, VoidCallback onPressed) {
    return IconButton(
      tooltip: 'More options',
      icon: const Icon(Icons.more_vert, size: 22),
      onPressed: onPressed,
    );
  }
}
