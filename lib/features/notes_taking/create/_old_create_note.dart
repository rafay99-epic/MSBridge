// // Dart imports:
// import 'dart:async';
// import 'dart:convert';

// // Flutter imports:
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';

// // Package imports:
// import 'package:flutter_bugfender/flutter_bugfender.dart';
// import 'package:flutter_quill/flutter_quill.dart';
// import 'package:flutter_quill/quill_delta.dart';
// import 'package:hive_flutter/hive_flutter.dart';
// import 'package:line_icons/line_icons.dart';
// import 'package:msbridge/features/notes_taking/create/widget/auto_save_bubble.dart';
// import 'package:msbridge/features/notes_taking/create/widget/bottom_toolbar.dart';
// import 'package:msbridge/features/notes_taking/create/widget/build_bottom_sheet_action.dart';
// import 'package:msbridge/features/notes_taking/create/widget/editor_pane.dart';
// import 'package:msbridge/features/notes_taking/create/widget/title_field.dart';
// import 'package:provider/provider.dart';
// import 'package:share_plus/share_plus.dart';

// // Project imports:
// import 'package:msbridge/config/feature_flag.dart';
// import 'package:msbridge/core/background_process/create_note_background.dart';
// import 'package:msbridge/core/database/note_taking/note_taking.dart';
// import 'package:msbridge/core/database/templates/note_template.dart';
// import 'package:msbridge/core/provider/auto_save_note_provider.dart';
// import 'package:msbridge/core/provider/note_summary_ai_provider.dart';
// import 'package:msbridge/core/provider/share_link_provider.dart';
// import 'package:msbridge/core/repo/note_taking_actions_repo.dart';
// import 'package:msbridge/core/repo/share_repo.dart';
// import 'package:msbridge/core/repo/template_repo.dart';
// import 'package:msbridge/core/services/network/internet_helper.dart';
// import 'package:msbridge/core/services/streak/streak_integration_service.dart';
// import 'package:msbridge/features/ai_summary/ai_summary_bottome_sheet.dart';
// import 'package:msbridge/features/notes_taking/export_notes/export_notes.dart';
// import 'package:msbridge/features/notes_taking/read/read_note_page.dart';
// import 'package:msbridge/features/templates/templates_hub.dart';
// import 'package:msbridge/widgets/appbar.dart';
// import 'package:msbridge/widgets/snakbar.dart';

// class CreateNote extends StatefulWidget {
//   const CreateNote({super.key, this.note, this.initialTemplate});

//   final NoteTakingModel? note;
//   final NoteTemplate? initialTemplate;

//   @override
//   State<CreateNote> createState() => _CreateNoteState();
// }

// class _CreateNoteState extends State<CreateNote>
//     with SingleTickerProviderStateMixin {
//   late QuillController _controller;
//   final TextEditingController _titleController = TextEditingController();
//   final TextEditingController _tagInputController = TextEditingController();
//   final ValueNotifier<List<String>> _tagsNotifier =
//       ValueNotifier<List<String>>(<String>[]);
//   final InternetHelper _internetHelper = InternetHelper();
//   Timer? _autoSaveTimer;
//   late SaveNoteResult result;

//   Timer? _debounceTimer;
//   final FocusNode _quillFocusNode = FocusNode();
//   final FocusNode _titleFocusNode = FocusNode();
//   final FocusNode _tagFocusNode = FocusNode();
//   final ValueNotifier<String> _currentFocusArea =
//       ValueNotifier<String>('editor');

//   final ValueNotifier<bool> _isSavingNotifier = ValueNotifier<bool>(false);
//   final ValueNotifier<bool> _showCheckmarkNotifier = ValueNotifier<bool>(false);
//   String _lastSavedContent = "";
//   NoteTakingModel? _currentNote;
//   bool _isSaving = false;
//   bool _isShareOperationInProgress = false;
//   StreamSubscription? _docChangesSub;

//   void _addTag(String rawTag) {
//     final tag = rawTag.trim();
//     if (tag.isEmpty) return;
//     final current = List<String>.from(_tagsNotifier.value);
//     if (!current.contains(tag)) {
//       current.add(tag);
//       _tagsNotifier.value = current;

//       _tagInputController.clear();

//       if (FeatureFlag.enableAutoSave) {
//         if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
//         _debounceTimer = Timer(const Duration(seconds: 1), () {
//           _currentFocusArea.value = 'tags';
//           _saveNote();
//         });
//       }
//     }
//   }

//   @override
//   void initState() {
//     super.initState();

//     if (widget.note != null) {
//       _titleController.text = widget.note!.noteTitle;
//       final String raw = (widget.note!.noteContent).trim();
//       if (raw.startsWith('[')) {
//         try {
//           final dynamic decoded = jsonDecode(raw);
//           if (decoded is List) {
//             _controller = QuillController(
//               document: Document.fromJson(decoded),
//               selection: const TextSelection.collapsed(offset: 0),
//             );
//           } else {
//             _controller = QuillController(
//               document: Document()..insert(0, widget.note!.noteContent),
//               selection: const TextSelection.collapsed(offset: 0),
//             );
//           }
//         } catch (e) {
//           FlutterBugfender.sendCrash(
//               'Error loading note: $e', StackTrace.current.toString());
//           FlutterBugfender.error('Error loading note: $e');
//           _controller = QuillController(
//             document: Document()..insert(0, widget.note!.noteContent),
//             selection: const TextSelection.collapsed(offset: 0),
//           );
//         }
//       } else {
//         _controller = QuillController(
//           document: Document()..insert(0, widget.note!.noteContent),
//           selection: const TextSelection.collapsed(offset: 0),
//         );
//       }
//       _currentNote = widget.note;
//       _tagsNotifier.value = List<String>.from(widget.note!.tags);
//     } else if (widget.initialTemplate != null) {
//       try {
//         _controller = QuillController(
//           document: Document.fromJson(
//               jsonDecode(widget.initialTemplate!.contentJson)),
//           selection: const TextSelection.collapsed(offset: 0),
//         );
//         _titleController.text = widget.initialTemplate!.title;
//         _tagsNotifier.value = List<String>.from(widget.initialTemplate!.tags);
//       } catch (e) {
//         FlutterBugfender.sendCrash(
//             'Error loading template: $e', StackTrace.current.toString());
//         FlutterBugfender.error('Error loading template: $e');
//         _controller = QuillController.basic();
//       }
//     } else {
//       _controller = QuillController.basic();
//     }

//     _attachControllerListeners();

//     _titleController.addListener(() {
//       if (_titleController.text.isNotEmpty) {
//         _currentFocusArea.value = 'title';
//       }
//     });

//     _tagInputController.addListener(() {
//       if (_tagInputController.text.isNotEmpty) {
//         _currentFocusArea.value = 'tags';
//       }
//     });

//     // Add focus listeners for accurate tracking
//     _titleFocusNode.addListener(() {
//       if (_titleFocusNode.hasFocus) {
//         _currentFocusArea.value = 'title';
//       }
//     });

//     _tagFocusNode.addListener(() {
//       if (_tagFocusNode.hasFocus) {
//         _currentFocusArea.value = 'tags';
//       }
//     });

//     _quillFocusNode.addListener(() {
//       if (_quillFocusNode.hasFocus) {
//         _currentFocusArea.value = 'editor';
//       }
//     });

//     if (FeatureFlag.enableAutoSave) {
//       // Auto-save when tags change
//       _tagsNotifier.addListener(() {
//         if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
//         _debounceTimer = Timer(const Duration(seconds: 2), () {
//           _currentFocusArea.value = 'tags';
//           _saveNote();
//         });
//       });
//     }

//     final autoSaveProvider =
//         Provider.of<AutoSaveProvider>(context, listen: false);
//     if (FeatureFlag.enableAutoSave && autoSaveProvider.autoSaveEnabled) {
//       startAutoSave();
//     }
//   }

//   @override
//   void dispose() {
//     _docChangesSub?.cancel();
//     _controller.dispose();
//     _titleController.dispose();
//     _tagInputController.dispose();
//     _tagsNotifier.dispose();
//     _internetHelper.dispose();
//     _autoSaveTimer?.cancel();
//     _debounceTimer?.cancel();
//     _quillFocusNode.dispose();
//     _titleFocusNode.dispose();
//     _tagFocusNode.dispose();
//     _currentFocusArea.dispose();
//     _isSavingNotifier.dispose();
//     _showCheckmarkNotifier.dispose();

//     super.dispose();
//   }

//   void startAutoSave() {
//     _autoSaveTimer?.cancel();
//     _autoSaveTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
//       final autoSaveProvider =
//           Provider.of<AutoSaveProvider>(context, listen: false);

//       if (!mounted || !autoSaveProvider.autoSaveEnabled) {
//         timer.cancel();
//         return;
//       }

//       String currentContent =
//           jsonEncode(_controller.document.toDelta().toJson());
//       if (currentContent != _lastSavedContent) {
//         _lastSavedContent = currentContent;
//         _saveNote();
//       }
//     });
//   }

//   void _attachControllerListeners() {
//     // Selection tracking removed; no custom copy/cut UI

//     // Debounced document changes for auto-save
//     if (FeatureFlag.enableAutoSave) {
//       _docChangesSub?.cancel();
//       _docChangesSub = _controller.document.changes.listen((event) {
//         if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
//         _debounceTimer = Timer(const Duration(seconds: 3), () {
//           _currentFocusArea.value = 'editor';
//           _saveNote();
//         });
//       });
//     }
//   }

//   void _reinitializeController(Document newDoc) {
//     // Dispose old controller to avoid leaks
//     _docChangesSub?.cancel();
//     _controller.dispose();
//     _controller = QuillController(
//       document: newDoc,
//       selection: const TextSelection.collapsed(offset: 0),
//     );
//     _attachControllerListeners();
//   }

//   Future<void> loadQuillContent(String noteContent) async {
//     try {
//       final jsonResult = jsonDecode(noteContent);
//       if (jsonResult is List) {
//         _controller = QuillController(
//           document: Document.fromJson(jsonResult),
//           selection: const TextSelection.collapsed(offset: 0),
//         );
//       } else {
//         _controller = QuillController(
//             document: Document()..insert(0, noteContent),
//             selection: const TextSelection.collapsed(offset: 0));
//       }
//     } catch (e) {
//       FlutterBugfender.sendCrash(
//           'Failed to load Quill content: $e', StackTrace.current.toString());
//       FlutterBugfender.error('Failed to load Quill content: $e');
//       _controller = QuillController(
//           document: Document()..insert(0, noteContent),
//           selection: const TextSelection.collapsed(offset: 0));
//     }
//   }

//   Future<void> _saveNote() async {
//     if (_isSaving) return; // prevent overlapping saves
//     _isSaving = true;
//     final autoSaveProvider =
//         Provider.of<AutoSaveProvider>(context, listen: false);
//     if (!mounted || !autoSaveProvider.autoSaveEnabled) {
//       _isSaving = false;
//       return;
//     }

//     final title = _titleController.text.trim();
//     String content;

//     _isSavingNotifier.value = true;
//     _showCheckmarkNotifier.value = false;

//     try {
//       try {
//         content = await encodeContent(_controller.document.toDelta());
//       } catch (e) {
//         FlutterBugfender.sendCrash(
//             'Failed to encode content: $e', StackTrace.current.toString());
//         content = _controller.document.toPlainText().trim();
//       }
//       if (title.isEmpty && content.isEmpty) {
//         _isSaving = false;
//         return;
//       }

//       if (_currentNote != null) {
//         result = await NoteTakingActions.updateNote(
//           note: _currentNote!,
//           title: title,
//           content: content,
//           isSynced: false,
//           tags: _tagsNotifier.value,
//         );
//       } else {
//         result = await NoteTakingActions.saveNote(
//           title: title,
//           content: content,
//           tags: _tagsNotifier.value,
//         );
//         if (result.success && result.note != null) {
//           _currentNote = result.note;
//           try {
//             await _updateStreakOnNoteCreation();
//           } catch (e) {
//             FlutterBugfender.sendCrash(
//                 'Streak update failed on note creation: $e',
//                 StackTrace.current.toString());
//           }
//         }
//       }

//       if (mounted) {
//         _isSavingNotifier.value = false;
//         _showCheckmarkNotifier.value = true;

//         if (_currentFocusArea.value == 'editor' && !_quillFocusNode.hasFocus) {
//           FocusScope.of(context).requestFocus(_quillFocusNode);
//         }

//         Future.delayed(const Duration(seconds: 1), () {
//           if (mounted) {
//             _showCheckmarkNotifier.value = false;
//           }
//         });
//       }
//     } catch (e) {
//       FlutterBugfender.sendCrash(
//           'Failed to save note: $e', StackTrace.current.toString());
//       if (mounted) {
//         _isSavingNotifier.value = false;
//         _showCheckmarkNotifier.value = false;
//         CustomSnackBar.show(context, "Error saving note: $e", isSuccess: false);
//       }
//     }
//     _isSaving = false;
//   }

//   Future<void> manualSaveNote() async {
//     String title = _titleController.text.trim();
//     String content;

//     try {
//       content = await encodeContent(_controller.document.toDelta());
//     } catch (e) {
//       FlutterBugfender.sendCrash(
//           'Failed to encode content: $e', StackTrace.current.toString());
//       FlutterBugfender.error('Failed to encode content: $e');
//       content = _controller.document.toPlainText().trim();
//     }
//     SaveNoteResult result;

//     try {
//       if (_currentNote != null) {
//         result = await NoteTakingActions.updateNote(
//           note: _currentNote!,
//           title: title,
//           content: content,
//           isSynced: false,
//           tags: _tagsNotifier.value,
//         );
//         if (result.success && mounted) {
//           CustomSnackBar.show(context, result.message, isSuccess: true);
//           Navigator.pop(context);
//         }
//       } else {
//         result = await NoteTakingActions.saveNote(
//           title: title,
//           content: content,
//           tags: _tagsNotifier.value,
//         );

//         if (result.success) {
//           _currentNote = result.note ?? _currentNote;
//           if (!mounted) return;
//           CustomSnackBar.show(context, result.message, isSuccess: true);

//           // Update streak when note is created
//           try {
//             await _updateStreakOnNoteCreation();
//           } catch (e) {
//             FlutterBugfender.sendCrash(
//                 'Streak update failed on note creation: $e',
//                 StackTrace.current.toString());
//           }
//           if (!mounted) return;
//           Navigator.pop(context);
//         }
//       }
//     } catch (e) {
//       FlutterBugfender.sendCrash(
//           'Failed to save note: $e', StackTrace.current.toString());
//       if (!mounted) return;
//       CustomSnackBar.show(context, "Error saving note: $e", isSuccess: false);
//     }
//   }

//   Future<void> _generateAiSummary(BuildContext context) async {
//     if (_internetHelper.connectivitySubject.value == false) {
//       CustomSnackBar.show(context, "Sorry No Internet Connection!",
//           isSuccess: false);
//       return;
//     }

//     final noteContent = _controller.document.toPlainText().trim();
//     if (noteContent.isEmpty || noteContent.length < 50) {
//       CustomSnackBar.show(context, "Add more content for AI summarization",
//           isSuccess: false);
//       return;
//     }
//     final noteSummaryProvider =
//         Provider.of<NoteSummaryProvider>(context, listen: false);

//     showAiSummaryBottomSheet(context);

//     noteSummaryProvider.summarizeNote(noteContent);
//   }

//   Future<void> _updateStreakOnNoteCreation() async {
//     try {
//       await StreakIntegrationService.onNoteCreated(context);
//     } catch (e) {
//       FlutterBugfender.sendCrash('Streak update failed on note creation: $e',
//           StackTrace.current.toString());
//     }
//   }

//   // Removed custom copy/cut methods; rely on platform selection menu
//   Future<void> _pasteText() async {
//     try {
//       final data = await Clipboard.getData('text/plain');
//       final text = data?.text ?? '';
//       if (text.isEmpty) {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text('Clipboard empty',
//                   style: TextStyle(
//                       fontSize: 12,
//                       color: Theme.of(context).colorScheme.onTertiary)),
//               duration: const Duration(seconds: 1),
//               behavior: SnackBarBehavior.floating,
//               margin: const EdgeInsets.all(8),
//               backgroundColor: Theme.of(context).colorScheme.tertiary,
//               shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(8)),
//             ),
//           );
//         }
//         return;
//       }
//       final selection = _controller.selection;
//       final length = selection.end - selection.start;
//       _controller.replaceText(
//         selection.start,
//         length < 0 ? 0 : length,
//         text,
//         selection,
//       );
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Pasted',
//                 style: TextStyle(
//                     fontSize: 12,
//                     color: Theme.of(context).colorScheme.onSecondary)),
//             duration: const Duration(seconds: 1),
//             behavior: SnackBarBehavior.floating,
//             margin: const EdgeInsets.all(8),
//             backgroundColor: Theme.of(context).colorScheme.secondary,
//             shape:
//                 RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//           ),
//         );
//       }
//     } catch (e) {
//       FlutterBugfender.sendCrash(
//           'Failed to paste text: $e', StackTrace.current.toString());
//       FlutterBugfender.error('Failed to paste text: $e');
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Paste failed',
//                 style: TextStyle(
//                     fontSize: 12,
//                     color: Theme.of(context).colorScheme.onError)),
//             duration: const Duration(seconds: 1),
//             behavior: SnackBarBehavior.floating,
//             margin: const EdgeInsets.all(8),
//             backgroundColor: Theme.of(context).colorScheme.error,
//             shape:
//                 RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//           ),
//         );
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);

//     return Scaffold(
//       backgroundColor: theme.colorScheme.surface,
//       appBar: CustomAppBar(
//         backbutton: true,
//         actions: [
//           // Only the most essential actions
//           IconButton(
//             tooltip: 'AI Summary',
//             icon: const Icon(LineIcons.robot, size: 22),
//             onPressed: () => _generateAiSummary(context),
//           ),
//           IconButton(
//             tooltip: 'Save',
//             icon: const Icon(LineIcons.save, size: 22),
//             onPressed: () async {
//               await manualSaveNote();
//             },
//           ),

//           // Paste action - direct access
//           IconButton(
//             tooltip: 'Paste',
//             icon: const Icon(Icons.paste, size: 22),
//             onPressed: _pasteText,
//           ),
//           // Read action - direct access (if note exists)
//           if (_currentNote != null)
//             IconButton(
//               tooltip: 'Read',
//               icon: const Icon(LineIcons.eye, size: 22),
//               onPressed: () {
//                 Navigator.push(
//                   context,
//                   PageRouteBuilder(
//                     pageBuilder: (context, animation, secondaryAnimation) =>
//                         ReadNotePage(note: _currentNote!),
//                     transitionsBuilder:
//                         (context, animation, secondaryAnimation, child) {
//                       return FadeTransition(opacity: animation, child: child);
//                     },
//                     transitionDuration: const Duration(milliseconds: 200),
//                   ),
//                 );
//               },
//             ),
//           // More actions button - opens bottom sheet
//           IconButton(
//             tooltip: 'More options',
//             icon: const Icon(Icons.more_vert, size: 22),
//             onPressed: () => _showMoreActionsBottomSheet(context),
//           ),
//         ],
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(8.0),
//         child: Stack(
//           children: [
//             Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 TitleField(
//                   controller: _titleController,
//                   focusNode: _titleFocusNode,
//                 ),
//                 TagsSection(
//                   theme: theme,
//                   tagsNotifier: _tagsNotifier,
//                   tagInputController: _tagInputController,
//                   tagFocusNode: _tagFocusNode,
//                   onAddTag: _addTag,
//                   onAutoSave: () {
//                     if (FeatureFlag.enableAutoSave) {
//                       if (_debounceTimer?.isActive ?? false) {
//                         _debounceTimer!.cancel();
//                       }
//                       _debounceTimer = Timer(const Duration(seconds: 1), () {
//                         _currentFocusArea.value = 'tags';
//                         _saveNote();
//                       });
//                     }
//                   },
//                 ),
//                 const SizedBox(height: 12),
//                 Expanded(
//                   child: EditorPane(
//                     controller: _controller,
//                     focusNode: _quillFocusNode,
//                   ),
//                 ),
//                 const SizedBox(height: 84),
//               ],
//             ),
//             BottomToolbar(
//               theme: theme,
//               controller: _controller,
//               ensureFocus: () {
//                 if (!_quillFocusNode.hasFocus) {
//                   FocusScope.of(context).requestFocus(_quillFocusNode);
//                 }
//               },
//             ),
//             if (FeatureFlag.enableAutoSave)
//               AutoSaveBubble(
//                 theme: theme,
//                 isSavingListenable: _isSavingNotifier,
//                 showCheckmarkListenable: _showCheckmarkNotifier,
//               ),
//           ],
//         ),
//       ),
//     );
//   }

//   Future<void> _openTemplatesPicker() async {
//     final theme = Theme.of(context);
//     final listenable = await TemplateRepo.getTemplatesListenable();
//     if (!mounted) return;

//     showModalBottomSheet(
//       context: context,
//       backgroundColor: theme.colorScheme.surface,
//       isScrollControlled: true,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
//       ),
//       builder: (ctx) {
//         return RepaintBoundary(
//           child: SafeArea(
//             child: Padding(
//               padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // Handle bar
//                   Center(
//                     child: Container(
//                       width: 40,
//                       height: 4,
//                       decoration: BoxDecoration(
//                         color: theme.colorScheme.outline.withValues(alpha: 0.3),
//                         borderRadius: BorderRadius.circular(2),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 20),
//                   // Title
//                   Text(
//                     'Select Template',
//                     style: theme.textTheme.titleLarge?.copyWith(
//                       fontWeight: FontWeight.w600,
//                       color: theme.colorScheme.onSurface,
//                     ),
//                   ),
//                   const SizedBox(height: 20),
//                   // Templates list
//                   Flexible(
//                     child: SizedBox(
//                       height: MediaQuery.of(ctx).size.height * 0.5,
//                       child: ValueListenableBuilder<Box<NoteTemplate>>(
//                         valueListenable: listenable,
//                         builder: (context, Box<NoteTemplate> box, _) {
//                           final items = box.values.toList();
//                           if (items.isEmpty) {
//                             return Center(
//                               child: Column(
//                                 mainAxisAlignment: MainAxisAlignment.center,
//                                 children: [
//                                   Icon(
//                                     LineIcons.fileAlt,
//                                     size: 48,
//                                     color: theme.colorScheme.primary
//                                         .withValues(alpha: 0.3),
//                                   ),
//                                   const SizedBox(height: 16),
//                                   Text(
//                                     'No templates yet',
//                                     style:
//                                         theme.textTheme.titleMedium?.copyWith(
//                                       color: theme.colorScheme.onSurface
//                                           .withValues(alpha: 0.7),
//                                     ),
//                                   ),
//                                   const SizedBox(height: 8),
//                                   Text(
//                                     'Create your first template to get started',
//                                     style: theme.textTheme.bodySmall?.copyWith(
//                                       color: theme.colorScheme.onSurface
//                                           .withValues(alpha: 0.5),
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             );
//                           }

//                           // Sort only once when items change
//                           items.sort(
//                               (a, b) => b.updatedAt.compareTo(a.updatedAt));

//                           return ListView.builder(
//                             itemCount: items.length,
//                             itemBuilder: (context, index) {
//                               final template = items[index];
//                               return RepaintBoundary(
//                                 child: Padding(
//                                   padding:
//                                       const EdgeInsets.symmetric(vertical: 6.0),
//                                   child: Material(
//                                     color: Colors.transparent,
//                                     child: InkWell(
//                                       borderRadius: BorderRadius.circular(12),
//                                       onTap: () async {
//                                         Navigator.pop(context);
//                                         await _applyTemplateInEditor(template);
//                                       },
//                                       child: Container(
//                                         padding: const EdgeInsets.all(16),
//                                         decoration: BoxDecoration(
//                                           color: theme.colorScheme.surface
//                                               .withValues(alpha: 0.3),
//                                           borderRadius:
//                                               BorderRadius.circular(12),
//                                           border: Border.all(
//                                             color: theme.colorScheme.outline
//                                                 .withValues(alpha: 0.1),
//                                           ),
//                                         ),
//                                         child: Row(
//                                           children: [
//                                             Container(
//                                               width: 48,
//                                               height: 48,
//                                               decoration: BoxDecoration(
//                                                 color: theme.colorScheme.primary
//                                                     .withValues(alpha: 0.1),
//                                                 borderRadius:
//                                                     BorderRadius.circular(12),
//                                               ),
//                                               child: Icon(
//                                                 LineIcons.fileAlt,
//                                                 size: 24,
//                                                 color:
//                                                     theme.colorScheme.primary,
//                                               ),
//                                             ),
//                                             const SizedBox(width: 16),
//                                             Expanded(
//                                               child: Column(
//                                                 crossAxisAlignment:
//                                                     CrossAxisAlignment.start,
//                                                 children: [
//                                                   Text(
//                                                     template.title,
//                                                     style: theme
//                                                         .textTheme.titleMedium
//                                                         ?.copyWith(
//                                                       fontWeight:
//                                                           FontWeight.w600,
//                                                       color: theme.colorScheme
//                                                           .onSurface,
//                                                     ),
//                                                   ),
//                                                   if (template
//                                                       .tags.isNotEmpty) ...[
//                                                     const SizedBox(height: 4),
//                                                     Text(
//                                                       template.tags.join(' · '),
//                                                       style: theme
//                                                           .textTheme.bodySmall
//                                                           ?.copyWith(
//                                                         color: theme.colorScheme
//                                                             .onSurface
//                                                             .withValues(
//                                                                 alpha: 0.7),
//                                                       ),
//                                                     ),
//                                                   ],
//                                                 ],
//                                               ),
//                                             ),
//                                             IconButton(
//                                               icon: const Icon(
//                                                   Icons.open_in_new,
//                                                   size: 20),
//                                               onPressed: () async {
//                                                 Navigator.pop(context);
//                                                 await Navigator.push(
//                                                   context,
//                                                   PageRouteBuilder(
//                                                     pageBuilder: (context,
//                                                             animation,
//                                                             secondaryAnimation) =>
//                                                         const TemplatesHubPage(),
//                                                     transitionsBuilder:
//                                                         (context,
//                                                             animation,
//                                                             secondaryAnimation,
//                                                             child) {
//                                                       return FadeTransition(
//                                                           opacity: animation,
//                                                           child: child);
//                                                     },
//                                                     transitionDuration:
//                                                         const Duration(
//                                                             milliseconds: 300),
//                                                   ),
//                                                 );
//                                               },
//                                               tooltip: 'Manage templates',
//                                             ),
//                                           ],
//                                         ),
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//                               );
//                             },
//                           );
//                         },
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }

//   Future<void> _applyTemplateInEditor(NoteTemplate t) async {
//     try {
//       final templateDoc = Document.fromJson(jsonDecode(t.contentJson));
//       // If editor empty, replace; else confirm replace vs insert
//       final isEmpty = _controller.document.isEmpty();
//       if (isEmpty) {
//         _reinitializeController(templateDoc);
//         setState(() {
//           _titleController.text = t.title;
//           _tagsNotifier.value = List<String>.from(t.tags);
//         });
//       } else {
//         final action = await showDialog<String>(
//           context: context,
//           builder: (dctx) {
//             final theme = Theme.of(dctx);
//             return AlertDialog(
//               backgroundColor: theme.colorScheme.surface,
//               title: Text('Apply template?',
//                   style: TextStyle(color: theme.colorScheme.primary)),
//               content: Text('Replace current content or insert at cursor?',
//                   style: TextStyle(color: theme.colorScheme.primary)),
//               actions: [
//                 TextButton(
//                     onPressed: () => Navigator.pop(dctx, 'insert'),
//                     child: const Text('Insert')),
//                 TextButton(
//                     onPressed: () => Navigator.pop(dctx, 'replace'),
//                     child: const Text('Replace')),
//                 TextButton(
//                     onPressed: () => Navigator.pop(dctx, 'cancel'),
//                     child: const Text('Cancel')),
//               ],
//             );
//           },
//         );
//         if (action == 'replace') {
//           _reinitializeController(templateDoc);
//           setState(() {
//             _titleController.text = t.title;
//             _tagsNotifier.value = List<String>.from(t.tags);
//           });
//         } else if (action == 'insert') {
//           final selection = _controller.selection;
//           final templateDelta = templateDoc.toDelta();
//           try {
//             final insertDelta = Delta()..retain(selection.start);
//             for (final op in templateDelta.toList()) {
//               if (op.isInsert) {
//                 insertDelta.insert(op.data, op.attributes);
//               }
//             }
//             // Use controller-level compose to keep history/selection mapping
//             _controller.compose(
//               insertDelta,
//               _controller.selection,
//               ChangeSource.local,
//             );
//             final insertedLen = templateDelta.length;
//             _controller.updateSelection(
//               TextSelection.collapsed(offset: selection.start + insertedLen),
//               ChangeSource.local,
//             );
//           } catch (e) {
//             FlutterBugfender.sendCrash(
//                 'Failed to apply template: $e', StackTrace.current.toString());
//             FlutterBugfender.error('Failed to apply template: $e');
//             _controller.replaceText(
//               selection.start,
//               0,
//               templateDoc.toPlainText(),
//               selection,
//             );
//           }
//         }
//       }
//       // Trigger save so it lands in Hive via existing flow
//       await _saveNote();
//       if (mounted) CustomSnackBar.show(context, 'Template applied');
//     } catch (e) {
//       FlutterBugfender.sendCrash(
//           'Failed to apply template: $e', StackTrace.current.toString());
//       FlutterBugfender.error('Failed to apply template: $e');
//       if (mounted) {
//         CustomSnackBar.show(context, 'Failed to apply template',
//             isSuccess: false);
//       }
//     }
//   }

//   void _showMoreActionsBottomSheet(BuildContext context) {
//     final theme = Theme.of(context);
//     final shareProvider =
//         Provider.of<ShareLinkProvider>(context, listen: false);
//     final hasShareEnabled =
//         shareProvider.shareLinksEnabled && _currentNote != null;

//     showModalBottomSheet(
//       context: context,
//       backgroundColor: theme.colorScheme.surface,
//       isScrollControlled: true,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
//       ),
//       builder: (context) {
//         return RepaintBoundary(
//             child: SafeArea(
//           child: Padding(
//             padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Handle bar
//                 Center(
//                   child: Container(
//                     width: 40,
//                     height: 4,
//                     decoration: BoxDecoration(
//                       color: theme.colorScheme.outline.withValues(alpha: 0.3),
//                       borderRadius: BorderRadius.circular(2),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//                 // Title
//                 Text(
//                   'More Actions',
//                   style: theme.textTheme.titleLarge?.copyWith(
//                     fontWeight: FontWeight.w600,
//                     color: theme.colorScheme.onSurface,
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//                 // Action buttons
//                 buildBottomSheetAction(
//                   icon: LineIcons.fileExport,
//                   title: 'Export',
//                   subtitle: 'Export note to various formats',
//                   onTap: () {
//                     Navigator.pop(context);
//                     showExportOptions(
//                       context,
//                       theme,
//                       _titleController,
//                       _controller,
//                     );
//                   },
//                   theme: theme,
//                 ),
//                 const SizedBox(height: 12),
//                 buildBottomSheetAction(
//                   icon: LineIcons.clone,
//                   title: 'Templates',
//                   subtitle: 'Use or create note templates',
//                   onTap: () {
//                     Navigator.pop(context);
//                     _openTemplatesPicker();
//                   },
//                   theme: theme,
//                 ),
//                 if (hasShareEnabled) ...[
//                   const SizedBox(height: 12),
//                   buildBottomSheetAction(
//                     icon: LineIcons.shareSquare,
//                     title: 'Share Link',
//                     subtitle: 'Create a shareable link for this note',
//                     onTap: () {
//                       Navigator.pop(context);
//                       _openShareSheet();
//                     },
//                     theme: theme,
//                   ),
//                 ],
//                 const SizedBox(height: 20),
//               ],
//             ),
//           ),
//         ));
//       },
//     );
//   }

//   Future<void> _openShareSheet() async {
//     final theme = Theme.of(context);
//     if (_currentNote == null) {
//       await manualSaveNote();
//       if (_currentNote == null) {
//         if (mounted) {
//           CustomSnackBar.show(context, 'Save the note before sharing',
//               isSuccess: false);
//         }
//         return;
//       }
//     }

//     final note = _currentNote!;
//     final status = await DynamicLink.getShareStatus(note.noteId!);
//     String? currentUrl = status.shareUrl.isNotEmpty ? status.shareUrl : null;
//     bool enabled = status.enabled;

//     if (!mounted) return;
//     showModalBottomSheet(
//       context: context,
//       backgroundColor: theme.colorScheme.surface,
//       isScrollControlled: true,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
//       ),
//       builder: (context) {
//         return StatefulBuilder(builder: (context, setStateSheet) {
//           return RepaintBoundary(
//             child: SafeArea(
//               child: Padding(
//                 padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     // Handle bar
//                     Center(
//                       child: Container(
//                         width: 40,
//                         height: 4,
//                         decoration: BoxDecoration(
//                           color:
//                               theme.colorScheme.outline.withValues(alpha: 0.3),
//                           borderRadius: BorderRadius.circular(2),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 20),
//                     // Title
//                     Text(
//                       'Share via Link',
//                       style: theme.textTheme.titleLarge?.copyWith(
//                         fontWeight: FontWeight.w600,
//                         color: theme.colorScheme.onSurface,
//                       ),
//                     ),
//                     const SizedBox(height: 20),
//                     // Share toggle card
//                     Container(
//                       padding: const EdgeInsets.all(16),
//                       decoration: BoxDecoration(
//                         color: theme.colorScheme.surface.withValues(alpha: 0.3),
//                         borderRadius: BorderRadius.circular(12),
//                         border: Border.all(
//                           color:
//                               theme.colorScheme.outline.withValues(alpha: 0.1),
//                         ),
//                       ),
//                       child: Row(
//                         children: [
//                           Container(
//                             width: 48,
//                             height: 48,
//                             decoration: BoxDecoration(
//                               color: theme.colorScheme.primary
//                                   .withValues(alpha: 0.1),
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                             child: Icon(
//                               LineIcons.shareSquare,
//                               size: 24,
//                               color: theme.colorScheme.primary,
//                             ),
//                           ),
//                           const SizedBox(width: 16),
//                           Expanded(
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Text(
//                                   'Share Link',
//                                   style: theme.textTheme.titleMedium?.copyWith(
//                                     fontWeight: FontWeight.w600,
//                                     color: theme.colorScheme.onSurface,
//                                   ),
//                                 ),
//                                 const SizedBox(height: 4),
//                                 Text(
//                                   enabled
//                                       ? 'Link is active and shareable'
//                                       : 'Enable to generate a view-only link',
//                                   style: theme.textTheme.bodySmall?.copyWith(
//                                     color: theme.colorScheme.onSurface
//                                         .withValues(alpha: 0.7),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                           if (_isShareOperationInProgress) ...[
//                             SizedBox(
//                               width: 20,
//                               height: 20,
//                               child: CircularProgressIndicator(
//                                 strokeWidth: 2,
//                                 valueColor: AlwaysStoppedAnimation<Color>(
//                                   theme.colorScheme.primary,
//                                 ),
//                               ),
//                             ),
//                           ] else ...[
//                             Switch(
//                               value: enabled,
//                               onChanged: (value) async {
//                                 if (_isShareOperationInProgress) return;

//                                 setStateSheet(() {
//                                   _isShareOperationInProgress = true;
//                                 });

//                                 try {
//                                   if (value) {
//                                     final url =
//                                         await DynamicLink.enableShare(note);
//                                     setStateSheet(() {
//                                       enabled = true;
//                                       currentUrl = url;
//                                     });
//                                     if (context.mounted) {
//                                       CustomSnackBar.show(
//                                           context, 'Share link enabled',
//                                           isSuccess: true);
//                                     }
//                                   } else {
//                                     await DynamicLink.disableShare(note);
//                                     setStateSheet(() {
//                                       enabled = false;
//                                       currentUrl = null;
//                                     });
//                                     if (context.mounted) {
//                                       CustomSnackBar.show(
//                                           context, 'Share link disabled',
//                                           isSuccess: false);
//                                     }
//                                   }
//                                 } catch (e) {
//                                   FlutterBugfender.sendCrash(
//                                       'Failed to enable/disable share: $e',
//                                       StackTrace.current.toString());
//                                   FlutterBugfender.error(
//                                       'Failed to enable/disable share: $e');
//                                   if (context.mounted) {
//                                     CustomSnackBar.show(context, e.toString(),
//                                         isSuccess: false);
//                                   }
//                                 } finally {
//                                   setStateSheet(() {
//                                     _isShareOperationInProgress = false;
//                                   });
//                                 }
//                               },
//                             ),
//                           ],
//                         ],
//                       ),
//                     ),
//                     if (currentUrl != null) ...[
//                       const SizedBox(height: 16),
//                       // URL display card
//                       Container(
//                         padding: const EdgeInsets.all(16),
//                         decoration: BoxDecoration(
//                           color:
//                               theme.colorScheme.surface.withValues(alpha: 0.3),
//                           borderRadius: BorderRadius.circular(12),
//                           border: Border.all(
//                             color: theme.colorScheme.outline
//                                 .withValues(alpha: 0.1),
//                           ),
//                         ),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               'Shareable Link',
//                               style: theme.textTheme.bodyMedium?.copyWith(
//                                 fontWeight: FontWeight.w600,
//                                 color: theme.colorScheme.onSurface,
//                               ),
//                             ),
//                             const SizedBox(height: 8),
//                             SelectableText(
//                               currentUrl!,
//                               style: TextStyle(
//                                 color: theme.colorScheme.primary
//                                     .withValues(alpha: 0.9),
//                                 fontSize: 14,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                       const SizedBox(height: 16),
//                       // Action buttons
//                       Row(
//                         children: [
//                           Expanded(
//                             child: ElevatedButton.icon(
//                               onPressed: () async {
//                                 await Clipboard.setData(
//                                     ClipboardData(text: currentUrl!));
//                                 if (context.mounted) {
//                                   CustomSnackBar.show(context, 'Link copied',
//                                       isSuccess: true);
//                                 }
//                               },
//                               icon: const Icon(LineIcons.copy, size: 18),
//                               label: const Text('Copy Link'),
//                               style: ElevatedButton.styleFrom(
//                                 padding:
//                                     const EdgeInsets.symmetric(vertical: 12),
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(8),
//                                 ),
//                               ),
//                             ),
//                           ),
//                           const SizedBox(width: 12),
//                           Expanded(
//                             child: OutlinedButton.icon(
//                               onPressed: () async {
//                                 try {
//                                   await SharePlus.instance.share(
//                                     ShareParams(
//                                       text: currentUrl!,
//                                       subject: 'Here is the link to the note',
//                                       title: 'Shared Note by MSBridge',
//                                     ),
//                                   );
//                                 } catch (e) {
//                                   FlutterBugfender.sendCrash(
//                                     'Failed to share link: $e',
//                                     StackTrace.current.toString(),
//                                   );
//                                   if (context.mounted) {
//                                     CustomSnackBar.show(
//                                       context,
//                                       'Failed to share link: $e',
//                                       isSuccess: false,
//                                     );
//                                   }
//                                 }
//                               },
//                               icon: const Icon(LineIcons.share, size: 18),
//                               label: const Text('Share'),
//                               style: OutlinedButton.styleFrom(
//                                 padding:
//                                     const EdgeInsets.symmetric(vertical: 12),
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(8),
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                     const SizedBox(height: 20),
//                   ],
//                 ),
//               ),
//             ),
//           );
//         });
//       },
//     );
//   }
// }
