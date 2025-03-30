import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:line_icons/line_icons.dart';
import 'package:msbridge/core/database/note_taking/note_taking.dart';
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
  bool isSaved = false;
  bool isSaving = false;
  String lastSavedContent = "";

  Timer? _debounceTimer;

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

    _controller.document.changes.listen((event) {
      if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
      _debounceTimer = Timer(const Duration(seconds: 3), () {
        saveNote();
      });
    });

    startAutoSave();
  }

  @override
  void dispose() {
    _controller.dispose();
    _titleController.dispose();
    _internetHelper.dispose();
    _autoSaveTimer?.cancel();

    super.dispose();
  }

  void startAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (!mounted) return;

      String currentContent =
          jsonEncode(_controller.document.toDelta().toJson());
      if (currentContent != lastSavedContent) {
        lastSavedContent = currentContent;
        saveNote();
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

  void saveNote() async {
    if (!mounted) return;

    String title = _titleController.text.trim();
    String content;

    try {
      content = jsonEncode(_controller.document.toDelta().toJson());
    } catch (e) {
      content = _controller.document.toPlainText().trim();
    }

    if (title.isEmpty && content.isEmpty) return;

    if (mounted) {
      setState(() {
        isSaving = true;
      });
    }

    try {
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

      if (!mounted) return;

      setState(() {
        isSaved = true;
        isSaving = false;
      });

      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;
        setState(() {
          isSaved = false;
        });
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isSaving = false;
      });
      CustomSnackBar.show(context, "Error saving note: $e");
    }
  }

  void manualSaveNote() async {
    String title = _titleController.text.trim();
    String content;

    try {
      content = jsonEncode(_controller.document.toDelta().toJson());
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
          if (isSaving)
            const Padding(
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
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(LineIcons.save),
                onPressed: manualSaveNote,
              ),
              if (isSaved)
                const Icon(Icons.check_circle, color: Colors.green, size: 20),
            ],
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
