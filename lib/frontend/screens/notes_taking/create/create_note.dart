import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:msbridge/backend/repo/note_taking_repo.dart';
import 'package:msbridge/frontend/widgets/snakbar.dart';

class CreateNote extends StatefulWidget {
  const CreateNote({super.key});

  @override
  State<CreateNote> createState() => _CreateNoteState();
}

class _CreateNoteState extends State<CreateNote>
    with SingleTickerProviderStateMixin {
  final QuillController _controller = QuillController.basic();
  final TextEditingController _titleController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    _titleController.dispose();
    super.dispose();
  }

  void _showDetailsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      backgroundColor: Theme.of(context).colorScheme.primary,
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    onPressed: () => saveNote(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      minimumSize: const Size(double.infinity, 48),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                    child: Text(
                      'Save',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.primary),
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  void saveNote() async {
    String title = _titleController.text.trim();
    String content = _controller.document.toPlainText().trim();

    SaveNoteResult result = await NoteTakingActions.saveNote(
      title: title,
      content: content,
    );

    if (result.success) {
      CustomSnackBar.show(context, result.message);
      _titleController.clear();
      _controller.clear();
      Navigator.pop(context);
    } else {
      CustomSnackBar.show(context, result.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      onPopInvoked: (didPop) {
        if (didPop) {}
      },
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: AppBar(
          title: const Text("Create Note"),
          automaticallyImplyLeading: true,
          backgroundColor: theme.colorScheme.surface,
          foregroundColor: theme.colorScheme.primary,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () {
                _showDetailsBottomSheet(context);
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
