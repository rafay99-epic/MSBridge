// Dart imports:
import 'dart:async';
import 'dart:convert';

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_bugfender/flutter_bugfender.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:provider/provider.dart';

// Project imports:
import 'package:msbridge/core/database/note_taking/note_taking.dart';
import 'package:msbridge/core/database/templates/note_template.dart';
import 'package:msbridge/core/provider/share_link_provider.dart';
import 'package:msbridge/features/notes_taking/create/services/ai_summary_manager.dart';
import 'package:msbridge/features/notes_taking/create/services/auto_save_manager.dart';
import 'package:msbridge/features/notes_taking/create/services/core_note_manager.dart';
import 'package:msbridge/features/notes_taking/create/services/export_manager.dart';
import 'package:msbridge/features/notes_taking/create/services/share_link_manager.dart';
import 'package:msbridge/features/notes_taking/create/services/template_manager.dart';
import 'package:msbridge/features/notes_taking/create/widget/auto_save_bubble.dart';
import 'package:msbridge/features/notes_taking/create/widget/bottom_toolbar.dart';
import 'package:msbridge/features/notes_taking/create/widget/editor_pane.dart';
import 'package:msbridge/features/notes_taking/create/widget/title_field.dart';
import 'package:msbridge/features/notes_taking/read/read_note_page.dart';
import 'package:msbridge/widgets/appbar.dart';

class CreateNote extends StatefulWidget {
  const CreateNote({super.key, this.note, this.initialTemplate});

  final NoteTakingModel? note;
  final NoteTemplate? initialTemplate;

  @override
  State<CreateNote> createState() => _CreateNoteState();
}

class _CreateNoteState extends State<CreateNote>
    with SingleTickerProviderStateMixin {
  late QuillController _controller;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _tagInputController = TextEditingController();
  final ValueNotifier<List<String>> _tagsNotifier =
      ValueNotifier<List<String>>(<String>[]);

  Timer? _debounceTimer;
  final FocusNode _quillFocusNode = FocusNode();
  final FocusNode _titleFocusNode = FocusNode();
  final FocusNode _tagFocusNode = FocusNode();
  final ValueNotifier<String> _currentFocusArea =
      ValueNotifier<String>('editor');

  final ValueNotifier<bool> _isSavingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _showCheckmarkNotifier = ValueNotifier<bool>(false);
  NoteTakingModel? _currentNote;
  final bool _isShareOperationInProgress = false;
  StreamSubscription? _docChangesSub;

  // Service managers
  final AutoSaveManager _autoSaveManager = AutoSaveManager();

  @override
  void initState() {
    super.initState();
    _initializeController();
    _loadInitialData();
    _startAutoSave();
    _attachControllerListeners();
  }

  @override
  void dispose() {
    _autoSaveManager.dispose();
    _debounceTimer?.cancel();
    _docChangesSub?.cancel();
    _controller.dispose();
    _titleController.dispose();
    _tagInputController.dispose();
    _tagsNotifier.dispose();
    _quillFocusNode.dispose();
    _titleFocusNode.dispose();
    _tagFocusNode.dispose();
    _currentFocusArea.dispose();
    _isSavingNotifier.dispose();
    _showCheckmarkNotifier.dispose();
    super.dispose();
  }

  void _initializeController() {
    _controller = QuillController.basic();
  }

  void _loadInitialData() {
    if (widget.note != null) {
      _currentNote = widget.note;
      _titleController.text = widget.note!.noteTitle;
      _tagsNotifier.value = List<String>.from(widget.note!.tags);
      CoreNoteManager.loadQuillContent(_controller, widget.note!.noteContent);
    } else if (widget.initialTemplate != null) {
      _titleController.text = widget.initialTemplate!.title;
      _tagsNotifier.value = List<String>.from(widget.initialTemplate!.tags);
      try {
        final templateDoc = Document.fromJson(
          jsonDecode(widget.initialTemplate!.contentJson),
        );
        _controller = QuillController(
          document: templateDoc,
          selection: const TextSelection.collapsed(offset: 0),
        );
      } catch (e) {
        FlutterBugfender.sendCrash(
          'Failed to load template: $e',
          StackTrace.current.toString(),
        );
        _controller = QuillController.basic();
      }
    }
  }

  void _startAutoSave() {
    _autoSaveManager.startAutoSave(
      context,
      _controller,
      _titleController,
      _tagsNotifier,
      _currentFocusArea,
      _isSavingNotifier,
      _showCheckmarkNotifier,
      _currentNote,
      (note) => setState(() => _currentNote = note),
    );
  }

  void _attachControllerListeners() {
    _autoSaveManager.attachControllerListeners(
      _controller,
      _currentFocusArea,
      _saveNote,
    );
  }

  void _saveNote() {
    // This will be handled by the AutoSaveManager internally
  }

  Future<void> _generateAiSummary(BuildContext context) async {
    final title = _titleController.text.trim();
    final content = _controller.document.toPlainText().trim();
    await AISummaryManager.generateAiSummary(context, title, content);
  }

  Future<void> _pasteText() async {
    await CoreNoteManager.pasteText(_controller, context);
  }

  Future<void> _openTemplatesPicker() async {
    await TemplateManager.openTemplatesPicker(
      context,
      (template) => TemplateManager.applyTemplateInEditor(
        template,
        _controller,
        _titleController,
        _tagsNotifier,
        (newDoc) => _reinitializeController(newDoc),
        context,
      ),
    );
  }

  void _reinitializeController(Document newDoc) {
    _docChangesSub?.cancel();
    _controller.dispose();
    _controller = QuillController(
      document: newDoc,
      selection: const TextSelection.collapsed(offset: 0),
    );
    _attachControllerListeners();
  }

  void _showMoreActionsBottomSheet(BuildContext context) {
    final shareProvider =
        Provider.of<ShareLinkProvider>(context, listen: false);
    final hasShareEnabled =
        shareProvider.shareLinksEnabled && _currentNote != null;

    ExportManager.showMoreActionsBottomSheet(
      context,
      _titleController,
      _controller,
      hasShareEnabled,
      _openTemplatesPicker,
      () => _openShareSheet(),
    );
  }

  Future<void> _openShareSheet() async {
    if (_currentNote != null) {
      await ShareLinkManager.openShareSheet(
        context,
        _currentNote!,
        ValueNotifier(_isShareOperationInProgress),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        backbutton: true,
        actions: [
          AISummaryManager.buildAIButton(
              context, () => _generateAiSummary(context)),
          CoreNoteManager.buildSaveButton(context, () async {
            await CoreNoteManager.manualSaveNote(
              context,
              _titleController,
              _controller,
              _tagsNotifier,
              _currentNote,
              (note) => setState(() => _currentNote = note),
            );
          }),
          CoreNoteManager.buildMoreOptionsButton(
              context, () => _showMoreActionsBottomSheet(context)),
          CoreNoteManager.buildPasteButton(context, _pasteText),
          if (_currentNote != null)
            CoreNoteManager.buildReadButton(context, () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ReadNotePage(note: _currentNote!),
                ),
              );
            }),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TitleField(
                    controller: _titleController,
                    focusNode: _titleFocusNode,
                  ),
                  const SizedBox(height: 16),
                  EditorPane(
                    controller: _controller,
                    focusNode: _quillFocusNode,
                  ),
                ],
              ),
            ),
          ),
          BottomToolbar(
            theme: Theme.of(context),
            controller: _controller,
            ensureFocus: () {
              if (!_quillFocusNode.hasFocus) {
                FocusScope.of(context).requestFocus(_quillFocusNode);
              }
            },
          ),
          AutoSaveBubble(
            theme: Theme.of(context),
            isSavingListenable: _isSavingNotifier,
            showCheckmarkListenable: _showCheckmarkNotifier,
          ),
        ],
      ),
    );
  }
}
