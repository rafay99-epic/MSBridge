import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bugfender/flutter_bugfender.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
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
import 'package:msbridge/core/database/templates/note_template.dart';
import 'package:msbridge/core/repo/template_repo.dart';
import 'package:msbridge/features/templates/templates_hub.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:msbridge/widgets/snakbar.dart';
import 'package:provider/provider.dart';
import 'package:msbridge/core/repo/share_repo.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import 'package:msbridge/core/provider/share_link_provider.dart';
import 'package:msbridge/core/services/streak/streak_integration_service.dart';
import "package:firebase_crashlytics/firebase_crashlytics.dart";

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
  final InternetHelper _internetHelper = InternetHelper();
  Timer? _autoSaveTimer;
  late SaveNoteResult result;

  Timer? _debounceTimer;
  final FocusNode _quillFocusNode = FocusNode();
  final FocusNode _titleFocusNode = FocusNode();
  final FocusNode _tagFocusNode = FocusNode();
  final ValueNotifier<String> _currentFocusArea =
      ValueNotifier<String>('editor');

  final ValueNotifier<bool> _isSavingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _showCheckmarkNotifier = ValueNotifier<bool>(false);
  String _lastSavedContent = "";
  NoteTakingModel? _currentNote;
  bool _isSaving = false;
  bool _hasSelection = false;
  bool _isShareOperationInProgress =
      false; // Added to prevent multiple share operations
  StreamSubscription? _docChangesSub;

  void _addTag(String rawTag) {
    final tag = rawTag.trim();
    if (tag.isEmpty) return;
    final current = List<String>.from(_tagsNotifier.value);
    if (!current.contains(tag)) {
      current.add(tag);
      _tagsNotifier.value = current;

      // Clear input immediately for better UX
      _tagInputController.clear();

      // Trigger auto-save for tags (faster than content auto-save)
      if (FeatureFlag.enableAutoSave) {
        if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
        _debounceTimer = Timer(const Duration(seconds: 1), () {
          _currentFocusArea.value = 'tags';
          _saveNote();
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();

    if (widget.note != null) {
      _titleController.text = widget.note!.noteTitle;
      final String raw = (widget.note!.noteContent).trim();
      if (raw.startsWith('[')) {
        try {
          final dynamic decoded = jsonDecode(raw);
          if (decoded is List) {
            _controller = QuillController(
              document: Document.fromJson(decoded),
              selection: const TextSelection.collapsed(offset: 0),
            );
          } else {
            _controller = QuillController(
              document: Document()..insert(0, widget.note!.noteContent),
              selection: const TextSelection.collapsed(offset: 0),
            );
          }
        } catch (e) {
          FlutterBugfender.sendCrash(
              'Error loading note: $e', StackTrace.current.toString());
          FlutterBugfender.error('Error loading note: $e');
          _controller = QuillController(
            document: Document()..insert(0, widget.note!.noteContent),
            selection: const TextSelection.collapsed(offset: 0),
          );
        }
      } else {
        _controller = QuillController(
          document: Document()..insert(0, widget.note!.noteContent),
          selection: const TextSelection.collapsed(offset: 0),
        );
      }
      _currentNote = widget.note;
      _tagsNotifier.value = List<String>.from(widget.note!.tags);
    } else if (widget.initialTemplate != null) {
      try {
        _controller = QuillController(
          document: Document.fromJson(
              jsonDecode(widget.initialTemplate!.contentJson)),
          selection: const TextSelection.collapsed(offset: 0),
        );
        _titleController.text = widget.initialTemplate!.title;
        _tagsNotifier.value = List<String>.from(widget.initialTemplate!.tags);
      } catch (e) {
        FlutterBugfender.sendCrash(
            'Error loading template: $e', StackTrace.current.toString());
        FlutterBugfender.error('Error loading template: $e');
        _controller = QuillController.basic();
      }
    } else {
      _controller = QuillController.basic();
    }

    _attachControllerListeners();

    // Add lightweight focus tracking
    _titleController.addListener(() {
      if (_titleController.text.isNotEmpty) {
        _currentFocusArea.value = 'title';
      }
    });

    _tagInputController.addListener(() {
      if (_tagInputController.text.isNotEmpty) {
        _currentFocusArea.value = 'tags';
      }
    });

    // Add focus listeners for accurate tracking
    _titleFocusNode.addListener(() {
      if (_titleFocusNode.hasFocus) {
        _currentFocusArea.value = 'title';
      }
    });

    _tagFocusNode.addListener(() {
      if (_tagFocusNode.hasFocus) {
        _currentFocusArea.value = 'tags';
      }
    });

    _quillFocusNode.addListener(() {
      if (_quillFocusNode.hasFocus) {
        _currentFocusArea.value = 'editor';
      }
    });

    if (FeatureFlag.enableAutoSave) {
      // Auto-save when tags change
      _tagsNotifier.addListener(() {
        if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
        _debounceTimer = Timer(const Duration(seconds: 2), () {
          _currentFocusArea.value = 'tags';
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
    _docChangesSub?.cancel();
    _controller.dispose();
    _titleController.dispose();
    _tagInputController.dispose();
    _tagsNotifier.dispose();
    _internetHelper.dispose();
    _autoSaveTimer?.cancel();
    _debounceTimer?.cancel();
    _quillFocusNode.dispose();
    _titleFocusNode.dispose();
    _tagFocusNode.dispose();
    _currentFocusArea.dispose();
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

  void _attachControllerListeners() {
    // Selection tracking
    _controller.addListener(() {
      final selection = _controller.selection;
      final bool hasSelection = selection.isValid && !selection.isCollapsed;
      if (_hasSelection != hasSelection && mounted) {
        setState(() {
          _hasSelection = hasSelection;
        });
      }
    });

    // Debounced document changes for auto-save
    if (FeatureFlag.enableAutoSave) {
      _docChangesSub?.cancel();
      _docChangesSub = _controller.document.changes.listen((event) {
        if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
        _debounceTimer = Timer(const Duration(seconds: 3), () {
          _currentFocusArea.value = 'editor';
          _saveNote();
        });
      });
    }
  }

  void _reinitializeController(Document newDoc) {
    // Dispose old controller to avoid leaks
    _docChangesSub?.cancel();
    _controller.dispose();
    _controller = QuillController(
      document: newDoc,
      selection: const TextSelection.collapsed(offset: 0),
    );
    _attachControllerListeners();
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
      FlutterBugfender.sendCrash(
          'Failed to load Quill content: $e', StackTrace.current.toString());
      FlutterBugfender.error('Failed to load Quill content: $e');
      _controller = QuillController(
          document: Document()..insert(0, noteContent),
          selection: const TextSelection.collapsed(offset: 0));
    }
  }

  Future<void> _saveNote() async {
    if (_isSaving) return; // prevent overlapping saves
    _isSaving = true;
    final autoSaveProvider =
        Provider.of<AutoSaveProvider>(context, listen: false);
    if (!mounted || !autoSaveProvider.autoSaveEnabled) {
      _isSaving = false;
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
        FlutterBugfender.sendCrash(
            'Failed to encode content: $e', StackTrace.current.toString());
        FlutterBugfender.error('Failed to encode content: $e');
        content = _controller.document.toPlainText().trim();
      }
      if (title.isEmpty && content.isEmpty) {
        _isSaving = false;
        return;
      }

      if (_currentNote != null) {
        result = await NoteTakingActions.updateNote(
          note: _currentNote!,
          title: title,
          content: content,
          isSynced: false,
          tags: _tagsNotifier.value,
        );
      } else {
        result = await NoteTakingActions.saveNote(
          title: title,
          content: content,
          tags: _tagsNotifier.value,
        );
        if (result.success && result.note != null) {
          _currentNote = result.note;

          // Update streak when note is created via auto-save
          try {
            await _updateStreakOnNoteCreation();
          } catch (e) {
            FlutterBugfender.sendCrash(
                'Streak update failed on note creation: $e',
                StackTrace.current.toString());
            FlutterBugfender.error('Streak update failed on note creation: $e');
          }
        }
      }

      if (mounted) {
        _isSavingNotifier.value = false;
        _showCheckmarkNotifier.value = true;

        // Only restore focus to editor if user was working there
        // This prevents interrupting title/tag input during auto-save
        if (_currentFocusArea.value == 'editor' && !_quillFocusNode.hasFocus) {
          FocusScope.of(context).requestFocus(_quillFocusNode);
        }

        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            _showCheckmarkNotifier.value = false;
          }
        });
      }
    } catch (e) {
      FlutterBugfender.sendCrash(
          'Failed to save note: $e', StackTrace.current.toString());
      FlutterBugfender.error('Failed to save note: $e');
      if (mounted) {
        _isSavingNotifier.value = false;
        _showCheckmarkNotifier.value = false;
        CustomSnackBar.show(context, "Error saving note: $e", isSuccess: false);
      }
    }
    _isSaving = false;
  }

  Future<void> manualSaveNote() async {
    String title = _titleController.text.trim();
    String content;

    try {
      content = await encodeContent(_controller.document.toDelta());
    } catch (e) {
      FlutterBugfender.sendCrash(
          'Failed to encode content: $e', StackTrace.current.toString());
      FlutterBugfender.error('Failed to encode content: $e');
      content = _controller.document.toPlainText().trim();
    }
    SaveNoteResult result;

    try {
      if (_currentNote != null) {
        result = await NoteTakingActions.updateNote(
          note: _currentNote!,
          title: title,
          content: content,
          isSynced: false,
          tags: _tagsNotifier.value,
        );
        if (result.success) {
          CustomSnackBar.show(context, result.message, isSuccess: true);
          Navigator.pop(context);
        }
      } else {
        result = await NoteTakingActions.saveNote(
          title: title,
          content: content,
          tags: _tagsNotifier.value,
        );

        if (result.success) {
          _currentNote = result.note ?? _currentNote;
          CustomSnackBar.show(context, result.message, isSuccess: true);

          // Update streak when note is created
          try {
            await _updateStreakOnNoteCreation();
          } catch (e) {
            FlutterBugfender.sendCrash(
                'Streak update failed on note creation: $e',
                StackTrace.current.toString());
            FlutterBugfender.error('Streak update failed on note creation: $e');
          }

          Navigator.pop(context);
        }
      }
    } catch (e) {
      FlutterBugfender.sendCrash(
          'Failed to save note: $e', StackTrace.current.toString());
      FlutterBugfender.error('Failed to save note: $e');
      CustomSnackBar.show(context, "Error saving note: $e", isSuccess: false);
    }
  }

  Future<void> _generateAiSummary(BuildContext context) async {
    if (_internetHelper.connectivitySubject.value == false) {
      CustomSnackBar.show(context, "Sorry No Internet Connection!",
          isSuccess: false);
      return;
    }

    final noteContent = _controller.document.toPlainText().trim();
    if (noteContent.isEmpty || noteContent.length < 50) {
      CustomSnackBar.show(context, "Add more content for AI summarization",
          isSuccess: false);
      return;
    }
    final noteSummaryProvider =
        Provider.of<NoteSummaryProvider>(context, listen: false);

    showAiSummaryBottomSheet(context);

    noteSummaryProvider.summarizeNote(noteContent);
  }

  Future<void> _updateStreakOnNoteCreation() async {
    try {
      await StreakIntegrationService.onNoteCreated(context);
    } catch (e) {
      FlutterBugfender.sendCrash('Streak update failed on note creation: $e',
          StackTrace.current.toString());
      FlutterBugfender.error('Streak update failed on note creation: $e');
    }
  }

  // Compact copy/paste methods
  Future<void> _copySelectedText() async {
    try {
      final selection = _controller.selection;
      final fullText = _controller.document.toPlainText();
      if (selection.isValid && !selection.isCollapsed) {
        final start = selection.start.clamp(0, fullText.length);
        final end = selection.end.clamp(0, fullText.length);
        final selectedText = fullText.substring(start, end);
        await Clipboard.setData(ClipboardData(text: selectedText));
        if (mounted) {
          // Compact snackbar that doesn't take much space
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Copied',
                  style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSecondary)),
              duration: const Duration(seconds: 1),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(8),
              backgroundColor: Theme.of(context).colorScheme.secondary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          );
        }
      }
    } catch (e) {
      FlutterBugfender.sendCrash(
          'Failed to copy text: $e', StackTrace.current.toString());
      FlutterBugfender.error('Failed to copy text: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Copy failed',
                style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onError)),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(8),
            backgroundColor: Theme.of(context).colorScheme.error,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    }
  }

  Future<void> _cutSelectedText() async {
    try {
      final selection = _controller.selection;
      final fullText = _controller.document.toPlainText();
      if (selection.isValid && !selection.isCollapsed) {
        final start = selection.start.clamp(0, fullText.length);
        final end = selection.end.clamp(0, fullText.length);
        final selectedText = fullText.substring(start, end);
        await Clipboard.setData(ClipboardData(text: selectedText));
        _controller.replaceText(
          selection.start,
          selection.end - selection.start,
          '',
          selection,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Cut',
                  style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSecondary)),
              duration: const Duration(seconds: 1),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(8),
              backgroundColor: Theme.of(context).colorScheme.secondary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          );
        }
      }
    } catch (e) {
      FlutterBugfender.sendCrash(
          'Failed to cut text: $e', StackTrace.current.toString());
      FlutterBugfender.error('Failed to cut text: $e');
      FirebaseCrashlytics.instance.recordError(
          Exception("Cut failed"), StackTrace.current,
          reason: "Cut failed");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cut failed',
                style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onError)),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(8),
            backgroundColor: Theme.of(context).colorScheme.error,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    }
  }

  Future<void> _pasteText() async {
    try {
      final data = await Clipboard.getData('text/plain');
      final text = data?.text ?? '';
      if (text.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Clipboard empty',
                  style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onTertiary)),
              duration: const Duration(seconds: 1),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(8),
              backgroundColor: Theme.of(context).colorScheme.tertiary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          );
        }
        return;
      }
      final selection = _controller.selection;
      final length = selection.end - selection.start;
      _controller.replaceText(
        selection.start,
        length < 0 ? 0 : length,
        text,
        selection,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pasted',
                style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSecondary)),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(8),
            backgroundColor: Theme.of(context).colorScheme.secondary,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } catch (e) {
      FlutterBugfender.sendCrash(
          'Failed to paste text: $e', StackTrace.current.toString());
      FlutterBugfender.error('Failed to paste text: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Paste failed',
                style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onError)),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(8),
            backgroundColor: Theme.of(context).colorScheme.error,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: CustomAppBar(
        backbutton: true,
        actions: [
          // Text editing actions (compact)
          if (_hasSelection) ...[
            IconButton(
              tooltip: 'Copy',
              icon: const Icon(Icons.copy, size: 20),
              onPressed: _copySelectedText,
            ),
            IconButton(
              tooltip: 'Cut',
              icon: const Icon(Icons.content_cut, size: 20),
              onPressed: _cutSelectedText,
            ),
          ],
          IconButton(
            tooltip: 'Paste',
            icon: const Icon(Icons.paste, size: 20),
            onPressed: _pasteText,
          ),

          // Main actions
          IconButton(
            icon: const Icon(LineIcons.robot, size: 22),
            onPressed: () => _generateAiSummary(context),
          ),
          IconButton(
            icon: const Icon(LineIcons.fileExport, size: 22),
            onPressed: () => showExportOptions(
              context,
              theme,
              _titleController,
              _controller,
            ),
          ),
          IconButton(
            tooltip: 'Templates',
            icon: const Icon(LineIcons.clone, size: 22),
            onPressed: _openTemplatesPicker,
          ),
          Consumer<ShareLinkProvider>(
            builder: (context, shareProvider, _) {
              if (!shareProvider.shareLinksEnabled || _currentNote == null) {
                return const SizedBox.shrink();
              }
              return IconButton(
                tooltip: 'Share link',
                icon: const Icon(LineIcons.shareSquare, size: 22),
                onPressed: _openShareSheet,
              );
            },
          ),
          IconButton(
            icon: const Icon(LineIcons.save, size: 22),
            onPressed: () async {
              await manualSaveNote();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: TextField(
                controller: _titleController,
                focusNode: _titleFocusNode,
                contextMenuBuilder: (BuildContext context,
                    EditableTextState editableTextState) {
                  return AdaptiveTextSelectionToolbar.editableText(
                    editableTextState: editableTextState,
                  );
                },
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
            // Compact Tags Section (Space Optimized)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Compact Tags Display
                  ValueListenableBuilder<List<String>>(
                    valueListenable: _tagsNotifier,
                    builder: (context, tags, _) {
                      if (tags.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return SizedBox(
                        height: 30,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: tags.length,
                          itemBuilder: (context, index) {
                            final tag = tags[index];
                            return Container(
                              margin: const EdgeInsets.only(right: 6),
                              child: Chip(
                                label: Text(
                                  tag,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: theme.colorScheme.primary
                                        .withOpacity(0.85),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                backgroundColor:
                                    theme.colorScheme.surfaceContainerHighest,
                                deleteIcon: Icon(
                                  Icons.close,
                                  size: 18,
                                  color: theme.colorScheme.primary
                                      .withOpacity(0.75),
                                ),
                                shape: StadiumBorder(
                                  side: BorderSide(
                                    color: theme.colorScheme.outlineVariant
                                        .withOpacity(0.15),
                                  ),
                                ),
                                onDeleted: () {
                                  final next = List<String>.from(tags)
                                    ..remove(tag);
                                  _tagsNotifier.value = next;

                                  // Auto-save when tag is deleted
                                  if (FeatureFlag.enableAutoSave) {
                                    if (_debounceTimer?.isActive ?? false) {
                                      _debounceTimer!.cancel();
                                    }
                                    _debounceTimer =
                                        Timer(const Duration(seconds: 1), () {
                                      _currentFocusArea.value = 'tags';
                                      _saveNote();
                                    });
                                  }
                                },
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),

                  // Compact Tag Input (Floating Style)
                  SizedBox(
                    height: 40,
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _tagInputController,
                            focusNode: _tagFocusNode,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (raw) {
                              final v = raw.trim();
                              if (v.isEmpty) return;
                              _addTag(v);
                              _tagInputController.clear();
                              FocusScope.of(context).unfocus();
                            },
                            contextMenuBuilder: (BuildContext context,
                                EditableTextState editableTextState) {
                              return AdaptiveTextSelectionToolbar.editableText(
                                editableTextState: editableTextState,
                              );
                            },
                            style: const TextStyle(fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'Add tag...',
                              hintStyle: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.primary
                                      .withOpacity(0.5)),
                              prefixIcon: Icon(Icons.tag,
                                  size: 16,
                                  color: theme.colorScheme.primary
                                      .withOpacity(0.7)),
                              suffixIcon: IconButton(
                                icon: Icon(Icons.add,
                                    size: 18,
                                    color: theme.colorScheme.primary
                                        .withOpacity(0.8)),
                                tooltip: 'Add tag',
                                onPressed: () {
                                  final v = _tagInputController.text.trim();
                                  if (v.isEmpty) return;
                                  _addTag(v);
                                  _tagInputController.clear();
                                  FocusScope.of(context).unfocus();
                                },
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                    minWidth: 32, minHeight: 32),
                              ),
                              filled: true,
                              fillColor: theme.colorScheme.surface,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide(
                                    color: theme.colorScheme.outlineVariant
                                        .withOpacity(0.15)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide(
                                    color: theme.colorScheme.outlineVariant
                                        .withOpacity(0.15)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide(
                                    color: theme.colorScheme.primary,
                                    width: 1.0),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SafeArea(
                child: QuillEditor.basic(
                  controller: _controller,
                  focusNode: _quillFocusNode,
                  config: QuillEditorConfig(
                    disableClipboard: false,
                    autoFocus: true,
                    placeholder: 'Note...',
                    expands: true,
                    onTapUp: (_, __) {
                      if (!_quillFocusNode.hasFocus) {
                        FocusScope.of(context).requestFocus(_quillFocusNode);
                      }
                      return false;
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Auto-save status indicators at bottom
            if (FeatureFlag.enableAutoSave) ...[
              ValueListenableBuilder<bool>(
                valueListenable: _isSavingNotifier,
                builder: (context, isSaving, child) {
                  if (isSaving) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: theme.colorScheme.secondary.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                theme.colorScheme.secondary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Auto-saving...",
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.secondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              ValueListenableBuilder<bool>(
                valueListenable: _showCheckmarkNotifier,
                builder: (context, showCheckmark, child) {
                  if (showCheckmark) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.green.withOpacity(0.3),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LineIcons.checkCircleAlt,
                            color: Colors.green,
                            size: 16,
                          ),
                          SizedBox(width: 8),
                          Text(
                            "Content saved",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],

            Listener(
              onPointerDown: (_) {
                if (!_quillFocusNode.hasFocus) {
                  FocusScope.of(context).requestFocus(_quillFocusNode);
                }
              },
              child: SafeArea(
                child: QuillSimpleToolbar(
                  controller: _controller,
                  config: const QuillSimpleToolbarConfig(
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openTemplatesPicker() async {
    final theme = Theme.of(context);
    final listenable = await TemplateRepo.getTemplatesListenable();
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(ctx).size.height * 0.6,
            child: ValueListenableBuilder(
              valueListenable: listenable,
              builder: (context, Box<NoteTemplate> box, _) {
                final items = box.values.toList()
                  ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
                if (items.isEmpty) {
                  return Center(
                    child: Text('No templates yet',
                        style: TextStyle(color: theme.colorScheme.primary)),
                  );
                }
                return ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final t = items[index];
                    return ListTile(
                      title: Text(t.title,
                          style: TextStyle(color: theme.colorScheme.primary)),
                      subtitle: t.tags.isEmpty
                          ? null
                          : Text(t.tags.join(' · '),
                              style: TextStyle(
                                  color: theme.colorScheme.primary
                                      .withOpacity(0.7))),
                      onTap: () async {
                        Navigator.pop(context);
                        await _applyTemplateInEditor(t);
                      },
                      trailing: IconButton(
                        icon: const Icon(Icons.open_in_new),
                        onPressed: () async {
                          Navigator.pop(context);
                          await Navigator.push(
                            context,
                            PageRouteBuilder(
                              pageBuilder:
                                  (context, animation, secondaryAnimation) =>
                                      const TemplatesHubPage(),
                              transitionsBuilder: (context, animation,
                                  secondaryAnimation, child) {
                                return FadeTransition(
                                    opacity: animation, child: child);
                              },
                              transitionDuration:
                                  const Duration(milliseconds: 300),
                            ),
                          );
                        },
                        tooltip: 'Manage templates',
                      ),
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _applyTemplateInEditor(NoteTemplate t) async {
    try {
      final templateDoc = Document.fromJson(jsonDecode(t.contentJson));
      // If editor empty, replace; else confirm replace vs insert
      final isEmpty = _controller.document.isEmpty();
      if (isEmpty) {
        _reinitializeController(templateDoc);
        setState(() {
          _titleController.text = t.title;
          _tagsNotifier.value = List<String>.from(t.tags);
        });
      } else {
        final action = await showDialog<String>(
          context: context,
          builder: (dctx) {
            final theme = Theme.of(dctx);
            return AlertDialog(
              backgroundColor: theme.colorScheme.surface,
              title: Text('Apply template?',
                  style: TextStyle(color: theme.colorScheme.primary)),
              content: Text('Replace current content or insert at cursor?',
                  style: TextStyle(color: theme.colorScheme.primary)),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(dctx, 'insert'),
                    child: const Text('Insert')),
                TextButton(
                    onPressed: () => Navigator.pop(dctx, 'replace'),
                    child: const Text('Replace')),
                TextButton(
                    onPressed: () => Navigator.pop(dctx, 'cancel'),
                    child: const Text('Cancel')),
              ],
            );
          },
        );
        if (action == 'replace') {
          _reinitializeController(templateDoc);
          setState(() {
            _titleController.text = t.title;
            _tagsNotifier.value = List<String>.from(t.tags);
          });
        } else if (action == 'insert') {
          final selection = _controller.selection;
          final templateDelta = templateDoc.toDelta();
          try {
            final insertDelta = Delta()..retain(selection.start);
            for (final op in templateDelta.toList()) {
              if (op.isInsert) {
                insertDelta.insert(op.data, op.attributes);
              }
            }
            // Use controller-level compose to keep history/selection mapping
            _controller.compose(
              insertDelta,
              _controller.selection,
              ChangeSource.local,
            );
            final insertedLen = templateDelta.length;
            _controller.updateSelection(
              TextSelection.collapsed(offset: selection.start + insertedLen),
              ChangeSource.local,
            );
          } catch (e) {
            FlutterBugfender.sendCrash(
                'Failed to apply template: $e', StackTrace.current.toString());
            FlutterBugfender.error('Failed to apply template: $e');
            _controller.replaceText(
              selection.start,
              0,
              templateDoc.toPlainText(),
              selection,
            );
          }
        }
      }
      // Trigger save so it lands in Hive via existing flow
      await _saveNote();
      if (mounted) CustomSnackBar.show(context, 'Template applied');
    } catch (e) {
      FlutterBugfender.sendCrash(
          'Failed to apply template: $e', StackTrace.current.toString());
      FlutterBugfender.error('Failed to apply template: $e');
      if (mounted) {
        CustomSnackBar.show(context, 'Failed to apply template',
            isSuccess: false);
      }
    }
  }

  Future<void> _openShareSheet() async {
    final theme = Theme.of(context);
    if (_currentNote == null) {
      await manualSaveNote();
      if (_currentNote == null) {
        if (mounted) {
          CustomSnackBar.show(context, 'Save the note before sharing',
              isSuccess: false);
        }
        return;
      }
    }

    final note = _currentNote!;
    final status = await ShareRepository.getShareStatus(note.noteId!);
    String? currentUrl = status.shareUrl.isNotEmpty ? status.shareUrl : null;
    bool enabled = status.enabled;

    // ignore: use_build_context_synchronously
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateSheet) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Share via link',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    Row(
                      children: [
                        if (_isShareOperationInProgress) ...[
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: theme.colorScheme.secondary
                                    .withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(3),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    theme.colorScheme.secondary,
                                  ),
                                  backgroundColor: theme.colorScheme.secondary
                                      .withOpacity(0.20),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Switch(
                          value: enabled,
                          onChanged: _isShareOperationInProgress
                              ? null
                              : (value) async {
                                  // Prevent multiple taps while operation is in progress
                                  if (_isShareOperationInProgress) return;

                                  setStateSheet(() {
                                    _isShareOperationInProgress = true;
                                  });

                                  try {
                                    if (value) {
                                      final url =
                                          await ShareRepository.enableShare(
                                              note);
                                      setStateSheet(() {
                                        enabled = true;
                                        currentUrl = url;
                                      });
                                      if (mounted) {
                                        CustomSnackBar.show(
                                            context, 'Share link enabled',
                                            isSuccess: true);
                                      }
                                    } else {
                                      await ShareRepository.disableShare(note);
                                      setStateSheet(() {
                                        enabled = false;
                                        currentUrl = null;
                                      });
                                      if (mounted) {
                                        CustomSnackBar.show(
                                            context, 'Share link disabled',
                                            isSuccess: false);
                                      }
                                    }
                                  } catch (e) {
                                    FlutterBugfender.sendCrash(
                                        'Failed to enable/disable share: $e',
                                        StackTrace.current.toString());
                                    FlutterBugfender.error(
                                        'Failed to enable/disable share: $e');
                                    if (mounted) {
                                      CustomSnackBar.show(context, e.toString(),
                                          isSuccess: false);
                                    }
                                  } finally {
                                    // Reset loading state
                                    setStateSheet(() {
                                      _isShareOperationInProgress = false;
                                    });
                                  }
                                },
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (currentUrl != null) ...[
                  SelectableText(
                    currentUrl!,
                    style: TextStyle(
                        color: theme.colorScheme.primary.withOpacity(0.9)),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () async {
                          await Clipboard.setData(
                              ClipboardData(text: currentUrl!));
                          if (mounted) {
                            CustomSnackBar.show(context, 'Link copied',
                                isSuccess: true);
                          }
                        },
                        icon: const Icon(LineIcons.copy),
                        label: const Text('Copy'),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () => Share.share(currentUrl!),
                        icon: const Icon(LineIcons.share),
                        label: const Text('Share'),
                      ),
                    ],
                  ),
                ] else ...[
                  Text(
                    'Enable to generate a view-only link anyone can open.',
                    style: TextStyle(
                        color: theme.colorScheme.primary.withOpacity(0.7)),
                  ),
                ]
              ],
            ),
          );
        });
      },
    );
  }
}
