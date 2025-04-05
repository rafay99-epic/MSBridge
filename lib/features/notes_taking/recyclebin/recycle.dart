import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:line_icons/line_icons.dart';
import 'package:msbridge/core/repo/hive_note_taking_repo.dart';
import 'package:msbridge/core/database/note_taking/note_taking.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:msbridge/core/repo/note_taking_actions_repo.dart';
import 'package:msbridge/features/notes_taking/widget/build_content.dart';
import 'package:msbridge/utils/empty_ui.dart';
import 'package:msbridge/utils/error.dart';
import 'package:msbridge/widgets/snakbar.dart';
import 'package:msbridge/widgets/warning_dialog_box.dart';

class DeletedNotes extends StatefulWidget {
  const DeletedNotes({super.key});

  @override
  State<DeletedNotes> createState() => _DeletedNotesState();
}

class _DeletedNotesState extends State<DeletedNotes> {
  bool _isSelectionMode = false;
  final List<String> _selectedNoteIds = [];

  void toggleNoteSelection(String noteId) {
    setState(() {
      if (_selectedNoteIds.contains(noteId)) {
        _selectedNoteIds.remove(noteId);
      } else {
        _selectedNoteIds.add(noteId);
      }
      _isSelectionMode = _selectedNoteIds.isNotEmpty;
    });
  }

  void exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedNoteIds.clear();
    });
  }

  void _deleteNotes(ThemeData theme) {
    if (_selectedNoteIds.length > 1) {
      showConfirmationDialog(
        context,
        theme,
        () {
          NoteTakingActions.permanentlyDeleteSelectedNotes(_selectedNoteIds)
              .then((result) {
            CustomSnackBar.show(context, result.message);
            exitSelectionMode();
          });
        },
        "Delete Notes?",
        "Are you sure you want to delete these ${_selectedNoteIds.length} notes permanently?",
        confirmButtonText: "Delete",
      );
    } else {
      NoteTakingActions.permanentlyDeleteSelectedNotes(_selectedNoteIds)
          .then((result) {
        CustomSnackBar.show(context, result.message);
        exitSelectionMode();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text("Recycle Bin"),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.primary,
        elevation: 2,
        centerTitle: true,
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(LineIcons.times),
                onPressed: exitSelectionMode,
              )
            : null,
        actions: _isSelectionMode
            ? [
                IconButton(
                  icon: const Icon(LineIcons.trash),
                  onPressed: () => _deleteNotes(theme),
                ),
                IconButton(
                  icon: const Icon(Icons.restore),
                  onPressed: () {
                    NoteTakingActions.restoreSelectedNotes(_selectedNoteIds)
                        .then((result) {
                      CustomSnackBar.show(context, result.message);
                      exitSelectionMode();
                    });
                  },
                ),
              ]
            : [],
        titleTextStyle: theme.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.primary,
        ),
      ),
      body: FutureBuilder<Box<NoteTakingModel>>(
        future: HiveNoteTakingRepo.getDeletedBox(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ErrorApp(errorMessage: 'Error: ${snapshot.error}');
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const EmptyNotesMessage(
              message: 'No deleted notes',
              description: 'Create some notes first.',
            );
          }

          final box = snapshot.data!;
          return ValueListenableBuilder<Box<NoteTakingModel>>(
            valueListenable: box.listenable(),
            builder: (context, box, _) {
              final notes = box.values.toList();

              return Padding(
                padding:
                    const EdgeInsets.only(top: 16.0, left: 12.0, right: 12.0),
                child: MasonryGridView.builder(
                  gridDelegate:
                      const SliverSimpleGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2),
                  itemCount: notes.length,
                  itemBuilder: (context, index) {
                    final note = notes[index];
                    return buildNoteItem(note, theme);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget buildNoteItem(NoteTakingModel note, ThemeData theme) {
    final isSelected = _selectedNoteIds.contains(note.noteId);
    return GestureDetector(
      onTap: () => toggleNoteSelection(note.noteId.toString()),
      onLongPress: () => toggleNoteSelection(note.noteId.toString()),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withOpacity(0.1)
              : theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: isSelected ? 6.0 : 3.0,
              spreadRadius: 1.0,
            ),
          ],
          border: isSelected
              ? Border.all(color: theme.colorScheme.primary, width: 2)
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                note.noteTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              buildContent(note.noteContent, theme),
              const SizedBox(height: 12),
              Text(
                '${DateTime.parse(note.updatedAt.toString()).day}/'
                '${DateTime.parse(note.updatedAt.toString()).month}/'
                '${DateTime.parse(note.updatedAt.toString()).year}',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
