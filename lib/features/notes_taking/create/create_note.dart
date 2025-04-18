import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:line_icons/line_icons.dart';
import 'package:msbridge/config/feature_flag.dart';
import 'package:msbridge/core/background_process/create_note_background.dart';
import 'package:msbridge/core/database/note_taking/note_taking.dart';
import 'package:msbridge/core/provider/auto_save_note_provider.dart';
import 'package:msbridge/core/provider/note_summary_ai_provider.dart';
import 'package:msbridge/core/repo/note_taking_actions_repo.dart';
import 'package:msbridge/core/services/network/internet_helper.dart';
import 'package:msbridge/features/ai_summary/ai_summary_bottome_sheet.dart';
import 'package:msbridge/features/notes_taking/export_notes/export_notes.dart';
import 'package:msbridge/widgets/appbar.dart';
import 'package:msbridge/widgets/snakbar.dart';
import 'package:provider/provider.dart';

class CreateNote extends StatefulWidget {
  const CreateNote({super.key, this.note});

  final NoteTakingModel? note;

  @override
  State<CreateNote> createState() => _CreateNoteState();
}

class _CreateNoteState extends State<CreateNote>
    with SingleTickerProviderStateMixin {
  late QuillController _controller;
  final TextEditingController _titleController = TextEditingController();
  final InternetHelper _internetHelper = InternetHelper();
  Timer? _autoSaveTimer;
  late SaveNoteResult result;

  Timer? _debounceTimer;
  final FocusNode _quillFocusNode = FocusNode();

  final ValueNotifier<bool> _isSavingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _showCheckmarkNotifier = ValueNotifier<bool>(false);
  String _lastSavedContent = "";

  @override
  void initState() {
    super.initState();

    if (widget.note != null) {
      _titleController.text = widget.note!.noteTitle;
      _controller = QuillController(
        document: Document.fromJson(jsonDecode(widget.note!.noteContent)),
        selection: const TextSelection.collapsed(offset: 0),
      );
    } else {
      _controller = QuillController.basic();
    }

    if (FeatureFlag.enableAutoSave) {
      _controller.document.changes.listen((event) {
        if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
        _debounceTimer = Timer(const Duration(seconds: 3), () {
          _saveNote();
        });
      });
    }

    final autoSaveProvider =
        Provider.of<AutoSaveProvider>(context, listen: false);
    if (FeatureFlag.enableAutoSave && autoSaveProvider.autoSaveEnabled) {
      startAutoSave();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _titleController.dispose();
    _internetHelper.dispose();
    _autoSaveTimer?.cancel();
    _debounceTimer?.cancel();
    _quillFocusNode.dispose();
    _isSavingNotifier.dispose();
    _showCheckmarkNotifier.dispose();

    super.dispose();
  }

  void startAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      final autoSaveProvider =
          Provider.of<AutoSaveProvider>(context, listen: false);

      if (!mounted || !autoSaveProvider.autoSaveEnabled) {
        timer.cancel();
        return;
      }

      String currentContent =
          jsonEncode(_controller.document.toDelta().toJson());
      if (currentContent != _lastSavedContent) {
        _lastSavedContent = currentContent;
        _saveNote();
      }
    });
  }

  Future<void> loadQuillContent(String noteContent) async {
    try {
      final jsonResult = jsonDecode(noteContent);
      if (jsonResult is List) {
        _controller = QuillController(
          document: Document.fromJson(jsonResult),
          selection: const TextSelection.collapsed(offset: 0),
        );
      } else {
        _controller = QuillController(
            document: Document()..insert(0, noteContent),
            selection: const TextSelection.collapsed(offset: 0));
      }
    } catch (e) {
      _controller = QuillController(
          document: Document()..insert(0, noteContent),
          selection: const TextSelection.collapsed(offset: 0));
    }
  }

  Future<void> _saveNote() async {
    final autoSaveProvider =
        Provider.of<AutoSaveProvider>(context, listen: false);
    if (!mounted || !autoSaveProvider.autoSaveEnabled) {
      return;
    }

    final title = _titleController.text.trim();
    String content;

    _isSavingNotifier.value = true;
    _showCheckmarkNotifier.value = false;

    try {
      try {
        content = await encodeContent(_controller.document.toDelta());
      } catch (e) {
        content = _controller.document.toPlainText().trim();
      }
      if (title.isEmpty && content.isEmpty) return;

      if (widget.note != null) {
        result = await NoteTakingActions.updateNote(
          note: widget.note!,
          title: title,
          content: content,
          isSynced: false,
        );
      } else {
        result = await NoteTakingActions.saveNote(
          title: title,
          content: content,
        );
      }

      if (mounted) {
        _isSavingNotifier.value = false;
        _showCheckmarkNotifier.value = true;
        FocusScope.of(context).requestFocus(_quillFocusNode);

        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            _showCheckmarkNotifier.value = false;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        _isSavingNotifier.value = false;
        _showCheckmarkNotifier.value = false;
        CustomSnackBar.show(context, "Error saving note: $e");
      }
    }
  }

  void manualSaveNote() async {
    String title = _titleController.text.trim();
    String content;

    try {
      content = await encodeContent(_controller.document.toDelta());
    } catch (e) {
      content = _controller.document.toPlainText().trim();
    }
    SaveNoteResult result;

    try {
      if (widget.note != null) {
        result = await NoteTakingActions.updateNote(
          note: widget.note!,
          title: title,
          content: content,
          isSynced: false,
        );
        if (result.success) {
          CustomSnackBar.show(context, result.message);
          Navigator.pop(context);
        }
      } else {
        result = await NoteTakingActions.saveNote(
          title: title,
          content: content,
        );

        if (result.success) {
          CustomSnackBar.show(context, result.message);
          Navigator.pop(context);
        }
      }
    } catch (e) {
      CustomSnackBar.show(context, "Error saving note: $e");
    }
  }

  Future<void> _generateAiSummary(BuildContext context) async {
    if (_internetHelper.connectivitySubject.value == false) {
      CustomSnackBar.show(context, "Sorry No Internet Connection!");
      return;
    }

    final noteContent = _controller.document.toPlainText().trim();
    if (noteContent.isEmpty || noteContent.length < 50) {
      CustomSnackBar.show(context, "Add more content for AI summarization");
      return;
    }
    final noteSummaryProvider =
        Provider.of<NoteSummaryProvider>(context, listen: false);

    showAiSummaryBottomSheet(context);

    noteSummaryProvider.summarizeNote(noteContent);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: CustomAppBar(
        backbutton: true,
        actions: [
          ValueListenableBuilder<bool>(
            valueListenable: _isSavingNotifier,
            builder: (context, isSaving, child) {
              if (FeatureFlag.enableAutoSave && isSaving) {
                return const Padding(
                  padding: EdgeInsets.only(right: 10.0),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 15,
                        height: 15,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 5),
                      Text(
                        "Auto Saving...",
                        style: TextStyle(
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                );
              } else {
                return const SizedBox.shrink();
              }
            },
          ),
          ValueListenableBuilder<bool>(
            valueListenable: _showCheckmarkNotifier,
            builder: (context, showCheckmark, child) {
              if (FeatureFlag.enableAutoSave && showCheckmark) {
                return const Padding(
                  padding: EdgeInsets.only(right: 10.0),
                  child: Row(
                    children: [
                      Icon(LineIcons.checkCircleAlt,
                          color: Colors.green, size: 20),
                      SizedBox(width: 5),
                      Text(
                        "Content Saved",
                        style: TextStyle(
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                );
              } else {
                return const SizedBox.shrink();
              }
            },
          ),
          IconButton(
            icon: const Icon(LineIcons.robot),
            onPressed: () => _generateAiSummary(context),
          ),
          IconButton(
            icon: const Icon(LineIcons.fileExport),
            onPressed: () => showExportOptions(
              context,
              theme,
              _titleController,
              _controller,
            ),
          ),
          IconButton(
            icon: const Icon(LineIcons.save),
            onPressed: manualSaveNote,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: 'Title',
                  hintStyle: TextStyle(
                    color: Colors.grey,
                  ),
                  border: InputBorder.none,
                ),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            Expanded(
              child: Builder(
                builder: (context) => QuillEditor.basic(
                  configurations: QuillEditorConfigurations(
                    controller: _controller,
                    sharedConfigurations:
                        const QuillSharedConfigurations(locale: Locale('en')),
                    placeholder: 'Note...',
                    expands: true,
                    customStyles: DefaultStyles(
                      paragraph: DefaultTextBlockStyle(
                          TextStyle(
                            fontSize: 16,
                            color: theme.colorScheme.primary,
                          ),
                          const VerticalSpacing(5, 0),
                          const VerticalSpacing(0, 0),
                          null),
                    ),
                  ),
                  focusNode: _quillFocusNode,
                ),
              ),
            ),
            const SizedBox(height: 30),
            QuillToolbar.simple(
              configurations: QuillSimpleToolbarConfigurations(
                controller: _controller,
                sharedConfigurations: const QuillSharedConfigurations(
                  locale: Locale('en'),
                ),
                multiRowsDisplay: false,
                toolbarSize: 40,
                showCodeBlock: true,
                showQuote: true,
                showLink: true,
                showFontSize: true,
                showFontFamily: true,
                showIndent: true,
                showDividers: true,
                showUnderLineButton: true,
                showLeftAlignment: true,
                showCenterAlignment: true,
                showRightAlignment: true,
                showJustifyAlignment: true,
                showHeaderStyle: true,
                showListNumbers: true,
                showListBullets: true,
                showListCheck: true,
                showStrikeThrough: true,
                showInlineCode: true,
                showColorButton: true,
                showBackgroundColorButton: true,
                showClearFormat: true,
                showAlignmentButtons: true,
                showUndo: true,
                showRedo: true,
                showDirection: false,
                showSearchButton: true,
                headerStyleType: HeaderStyleType.buttons,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
