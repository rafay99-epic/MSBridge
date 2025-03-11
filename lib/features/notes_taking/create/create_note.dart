import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:msbridge/core/repo/note_taking_actions_repo.dart';
import 'package:msbridge/core/database/note_taking/note_taking.dart';
import 'package:msbridge/widgets/appbar.dart';
import 'package:msbridge/widgets/snakbar.dart';

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
      try {
        _controller = QuillController(
          document: Document.fromJson(jsonDecode(widget.note!.noteContent)),
          selection: const TextSelection.collapsed(offset: 0),
        );
      } catch (e) {
        _controller = QuillController(
          document: Document(),
          selection: const TextSelection.collapsed(offset: 0),
        );
        _controller.document.insert(0, widget.note!.noteContent);
      }
    } else {
      _controller = QuillController.basic();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _titleController.dispose();
    super.dispose();
  }

  Future<bool> _performSave({bool showSnackBar = true}) async {
    String title = _titleController.text.trim();
    String content = _controller.document.toPlainText().trim();

    try {
      if (widget.note != null) {
        await NoteTakingActions.updateNote(
          note: widget.note!,
          title: title,
          content: content,
          isSynced: false,
        );
      } else {
        await NoteTakingActions.saveNote(
          title: title,
          content: content,
        );
      }
      if (showSnackBar && context.mounted) {
        CustomSnackBar.show(context, "Note saved.");
      }
      return true;
    } catch (e) {
      if (context.mounted) {
        CustomSnackBar.show(context, "Error saving note: $e");
      }
      return false;
    }
  }

  Future<void> _saveNoteOnPop() async {
    await _performSave(showSnackBar: false);
  }

  void saveNote() async {
    bool success = await _performSave();

    if (success) {
      _titleController.clear();
      _controller.clear();
      if (context.mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      onPopInvoked: (didPop) async {
        if (didPop) {
          await _saveNoteOnPop();
        }
      },
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: CustomAppBar(
          title: widget.note == null ? "Create Note" : "Edit Note",
          backbutton: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.save),
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
      ),
    );
  }
}
