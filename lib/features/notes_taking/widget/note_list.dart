import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:msbridge/core/database/note_taking/note_taking.dart';
import 'package:msbridge/core/provider/pin_note_provider.dart';
import 'package:msbridge/features/notes_taking/create/create_note.dart';
import 'package:msbridge/utils/empty_ui.dart';
import 'package:msbridge/features/notes_taking/widget/note_taking_card.dart';

class NoteList extends StatelessWidget {
  const NoteList({
    super.key,
    required this.notes,
    required this.noteProvider,
    required this.theme,
    required this.isSelectionMode,
    required this.selectedNoteIds,
    required this.enterSelectionMode,
    required this.toggleNoteSelection,
  });

  final List<NoteTakingModel> notes;
  final NoteePinProvider noteProvider;
  final ThemeData theme;
  final bool isSelectionMode;
  final List<String> selectedNoteIds;
  final Function(String) enterSelectionMode;
  final Function(String) toggleNoteSelection;

  @override
  Widget build(BuildContext context) {
    if (notes.isEmpty) {
      return const EmptyNotesMessage(
        message: 'No Notes Yet',
        description: 'Tap + to create a new note',
      );
    }

    final pinnedNotes = notes
        .where((note) => noteProvider.isNotePinned(note.noteId.toString()))
        .toList();
    final unpinnedNotes = notes
        .where((note) => !noteProvider.isNotePinned(note.noteId.toString()))
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (pinnedNotes.isNotEmpty) _buildSectionTitle("Pinned Notes"),
          if (pinnedNotes.isNotEmpty) _buildNoteGrid(pinnedNotes),
          _buildSectionTitle("All Notes"),
          _buildNoteGrid(unpinnedNotes),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 8.0),
      child: Text(
        title,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildNoteGrid(List<NoteTakingModel> notesList) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: MasonryGridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        itemCount: notesList.length,
        itemBuilder: (context, index) {
          final note = notesList[index];
          return GestureDetector(
            onTap: () => handleNoteTap(context, note),
            onLongPress: () => handleNoteLongPress(note),
            child: AnimatedOpacity(
              opacity: 1.0,
              duration: const Duration(milliseconds: 300),
              child: NoteCard(
                note: note,
                isSelected: selectedNoteIds.contains(note.noteId.toString()),
                isSelectionMode: isSelectionMode,
              ),
            ),
          );
        },
      ),
    );
  }

  void handleNoteTap(BuildContext context, NoteTakingModel note) async {
    if (isSelectionMode) {
      toggleNoteSelection(note.noteId.toString());
    } else {
      await Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              CreateNote(note: note),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 300),
        ),
      );
    }
  }

  void handleNoteLongPress(NoteTakingModel note) {
    if (!isSelectionMode) {
      enterSelectionMode(note.noteId.toString());
    }
  }
}
