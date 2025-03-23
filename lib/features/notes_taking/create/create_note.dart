import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:msbridge/core/file_convters/markdown/markdown_convter.dart';
import 'package:msbridge/core/file_convters/pdf/pdfconvter.dart';
import 'package:msbridge/core/repo/note_taking_actions_repo.dart';
import 'package:msbridge/core/database/note_taking/note_taking.dart';
import 'package:msbridge/widgets/appbar.dart';
import 'package:msbridge/widgets/snakbar.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

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

  void showActionSheet() {
    showCupertinoModalBottomSheet(
      context: context,
      builder: (context) => Material(
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.picture_as_pdf),
                title: const Text('Export to PDF'),
                onTap: () => {
                  PdfExporter.exportToPdf(
                      context, _titleController.text.trim(), _controller),
                  Navigator.pop(context),
                },
              ),
              ListTile(
                leading: const Icon(Icons.text_snippet),
                title: const Text('Export to Markdown'),
                onTap: () {
                  Navigator.pop(context);

                  MarkdownExporter.exportToMarkdown(
                      context, _titleController.text.trim(), _controller);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: CustomAppBar(backbutton: true, actions: [
        IconButton(
          icon: const Icon(Icons.more_horiz),
          onPressed: showActionSheet,
        ),
        IconButton(
          icon: const Icon(Icons.save),
          onPressed: saveNote,
        ),
      ]),
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
            QuillToolbar.simple(
              configurations: QuillSimpleToolbarConfigurations(
                controller: _controller,
                sharedConfigurations: const QuillSharedConfigurations(
                  locale: Locale('en'),
                ),
                multiRowsDisplay: false,
                toolbarSize: 50,
                showCodeBlock: true,
                showQuote: true,
                showLink: true,
                showFontSize: true,
                showFontFamily: true,
                showIndent: true,
                headerStyleType: HeaderStyleType.buttons,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
