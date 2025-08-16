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
import 'package:msbridge/core/repo/share_repo.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import 'package:msbridge/core/provider/share_link_provider.dart';
import 'package:msbridge/core/services/streak_integration_service.dart';
import "package:firebase_crashlytics/firebase_crashlytics.dart";

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
      _controller = QuillController(
        document: Document.fromJson(jsonDecode(widget.note!.noteContent)),
        selection: const TextSelection.collapsed(offset: 0),
      );
      _currentNote = widget.note;
      _tagsNotifier.value = List<String>.from(widget.note!.tags);
    } else {
      _controller = QuillController.basic();
    }

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
      _controller.document.changes.listen((event) {
        if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
        _debounceTimer = Timer(const Duration(seconds: 3), () {
          _currentFocusArea.value = 'editor';
          _saveNote();
        });
      });

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
            FirebaseCrashlytics.instance.recordError(e, StackTrace.current,
                reason: "Streak update failed on note creation");
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
            FirebaseCrashlytics.instance.recordError(e, StackTrace.current,
                reason: "Streak update failed on note creation");
          }

          Navigator.pop(context);
        }
      }
    } catch (e) {
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
      FirebaseCrashlytics.instance.recordError(e, StackTrace.current,
          reason: "Streak update failed on note creation");
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
          Consumer<ShareLinkProvider>(
            builder: (context, shareProvider, _) {
              if (!shareProvider.shareLinksEnabled) {
                return const SizedBox.shrink();
              }
              if (_currentNote == null) {
                return const SizedBox.shrink();
              }
              return IconButton(
                tooltip: 'Share link',
                icon: const Icon(LineIcons.shareSquare),
                onPressed: _openShareSheet,
              );
            },
          ),
          IconButton(
            icon: const Icon(LineIcons.save),
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
            Container(
              margin: const EdgeInsets.only(bottom: 8.0),
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
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                backgroundColor:
                                    theme.colorScheme.surfaceContainerHighest,
                                deleteIcon: Icon(
                                  Icons.close,
                                  size: 18,
                                  color: theme.colorScheme.primary,
                                ),
                                onDeleted: () {
                                  final next = List<String>.from(tags)
                                    ..remove(tag);
                                  _tagsNotifier.value = next;

                                  // Auto-save when tag is deleted
                                  if (FeatureFlag.enableAutoSave) {
                                    if (_debounceTimer?.isActive ?? false)
                                      _debounceTimer!.cancel();
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
                  Container(
                    height: 40,
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _tagInputController,
                            focusNode: _tagFocusNode,
                            textInputAction: TextInputAction.done,
                            onSubmitted: _addTag,
                            style: TextStyle(fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'Add tag...',
                              hintStyle:
                                  TextStyle(fontSize: 12, color: Colors.grey),
                              prefixIcon: Icon(Icons.tag, size: 16),
                              suffixIcon: IconButton(
                                icon: Icon(Icons.add, size: 18),
                                tooltip: 'Add tag',
                                onPressed: () =>
                                    _addTag(_tagInputController.text),
                                padding: EdgeInsets.zero,
                                constraints:
                                    BoxConstraints(minWidth: 32, minHeight: 32),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide(
                                    color: theme.colorScheme.outlineVariant),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide(
                                    color: theme.colorScheme.outlineVariant),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide(
                                    color: theme.colorScheme.primary,
                                    width: 1.5),
                              ),
                              contentPadding: EdgeInsets.symmetric(
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
            const SizedBox(height: 16),
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
                    Switch(
                      value: enabled,
                      onChanged: (value) async {
                        try {
                          if (value) {
                            final url = await ShareRepository.enableShare(note);
                            setStateSheet(() {
                              enabled = true;
                              currentUrl = url;
                            });
                            if (mounted) {
                              CustomSnackBar.show(context, 'Share link enabled',
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
                          if (mounted) {
                            CustomSnackBar.show(context, e.toString(),
                                isSuccess: false);
                          }
                        }
                      },
                    )
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
