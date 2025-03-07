import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:msbridge/backend/hive/note_taking/note_taking.dart';
import 'package:msbridge/backend/repo/hive_note_taking_repo.dart';
import 'package:msbridge/frontend/utils/uuid.dart';
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

  // void saveNote() async {
  //   final FirebaseAuth auth = FirebaseAuth.instance;
  //   User? user = auth.currentUser;
  //   if (user == null) {
  //     return;
  //   }
  //   String userId = user.uid;
  //   String title = _titleController.text.trim();
  //   String content = _controller.document.toPlainText().trim();

  //   if (title.isNotEmpty || content.isNotEmpty) {
  //     NoteTakingModel note = NoteTakingModel(
  //       noteTitle: title,
  //       noteContent: content,
  //       isSynced: false,
  //       isDeleted: false,
  //       updatedAt: DateTime.now(),
  //       userId: userId,
  //     );

  //     await HiveNoteTakingRepo.addNote(note);
  //     Navigator.pop(context); // Close the bottom sheet
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('Note Saved Successfully!')),
  //     );
  //   } else {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('Please enter some content or title')),
  //     );
  //   }
  // }

  void saveNote() async {
    String noteUUID = generateUuid();
    final FirebaseAuth auth = FirebaseAuth.instance;
    User? user = auth.currentUser;
    if (user == null) {
      print("====================");
      print("User is not logged in");
      print("====================");
      return;
    }
    String userId = user.uid;
    String title = _titleController.text;
    String content = _controller.document.toPlainText();

    if (title.isNotEmpty || content.isNotEmpty) {
      NoteTakingModel note = NoteTakingModel(
        noteId: noteUUID,
        noteTitle: title,
        noteContent: content,
        isSynced: false,
        isDeleted: false,
        updatedAt: DateTime.now(),
        userId: userId,
      );

      await HiveNoteTakingRepo.addNote(note);
      print("=======================================================");
      print("Note Saved: ${note.toMap()}"); // Print the saved note
      print("=======================================================");
      // Fetch all notes from Hive to verify
      List<NoteTakingModel> allNotes = await HiveNoteTakingRepo.getNotes();
      print("=======================================================");

      print("All Notes in Hive:");

      for (var n in allNotes) {
        print(n.toMap());
      }
      print("=======================================================");

      Navigator.pop(context); // Close the bottom sheet
      CustomSnackBar.show(context, "Note Saved Successfully!");
    } else {
      print("=======================================================");

      print("Empty note not saved");
      print("=======================================================");
      CustomSnackBar.show(
          context, "Sorry Cotnent Not Saved! Enter Something to continue");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      onPopInvoked: (didPop) {
        if (didPop) {
          Navigator.of(context).pop();
        }
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
