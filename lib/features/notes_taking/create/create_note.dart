import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:line_icons/line_icons.dart';
import 'package:msbridge/core/database/note_taking/note_taking.dart';
import 'package:msbridge/core/file_convters/markdown/markdown_convter.dart';
import 'package:msbridge/core/file_convters/pdf/pdfconvter.dart';
import 'package:msbridge/core/provider/note_summary_ai_provider.dart';
import 'package:msbridge/core/repo/note_taking_actions_repo.dart';
import 'package:msbridge/core/services/network/internet_helper.dart';
import 'package:msbridge/features/ai_summary/ai_summary_bottome_sheet.dart';
import 'package:msbridge/widgets/appbar.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
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

  @override
  void initState() {
    super.initState();

    if (widget.note != null) {
      _titleController.text = widget.note!.noteTitle;
      _loadQuillContent(widget.note!.noteContent);
    } else {
      _controller = QuillController.basic();
    }
  }

  Future<void> _loadQuillContent(String noteContent) async {
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

  @override
  void dispose() {
    _controller.dispose();
    _titleController.dispose();
    _internetHelper.dispose();

    super.dispose();
  }

  void saveNote() async {
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
          IconButton(
            icon: const Icon(LineIcons.robot),
            onPressed: () {
              _generateAiSummary(context);
            },
          ),
          IconButton(
            icon: const Icon(LineIcons.fileExport),
            onPressed: () {
              showCupertinoModalBottomSheet(
                backgroundColor: theme.colorScheme.surface,
                context: context,
                builder: (context) => Material(
                  color: theme.colorScheme.surface,
                  child: SafeArea(
                    top: false,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        ListTile(
                          iconColor: theme.colorScheme.primary,
                          leading: const Icon(LineIcons.pdfFileAlt),
                          title: Text(
                            'Export to PDF',
                            style: TextStyle(color: theme.colorScheme.primary),
                          ),
                          onTap: () => {
                            PdfExporter.exportToPdf(context,
                                _titleController.text.trim(), _controller),
                            Navigator.pop(context),
                          },
                        ),
                        ListTile(
                          iconColor: theme.colorScheme.primary,
                          leading: const Icon(LineIcons.markdown),
                          title: Text(
                            'Export to Markdown',
                            style: TextStyle(color: theme.colorScheme.primary),
                          ),
                          onTap: () {
                            Navigator.pop(context);

                            MarkdownExporter.exportToMarkdown(context,
                                _titleController.text.trim(), _controller);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(LineIcons.save),
            onPressed: saveNote,
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
              child: QuillEditor.basic(
                configurations: QuillEditorConfigurations(
                  controller: _controller,
                  sharedConfigurations: const QuillSharedConfigurations(
                    locale: Locale('en'),
                  ),
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
            const SizedBox(height: 8),
            QuillToolbar.simple(
              configurations: QuillSimpleToolbarConfigurations(
                controller: _controller,
                sharedConfigurations: const QuillSharedConfigurations(
                  locale: Locale('en'),
                ),
                multiRowsDisplay: MediaQuery.of(context).size.width < 400,
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
