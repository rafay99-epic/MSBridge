import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:line_icons/line_icons.dart';
import 'package:msbridge/core/repo/hive_note_taking_repo.dart';
import 'package:msbridge/core/database/note_taking/note_taking.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:msbridge/core/repo/note_taking_actions_repo.dart';
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

  void _enterSelectionMode(String noteId) {
    setState(() {
      _isSelectionMode = true;
      _selectedNoteIds.add(noteId);
    });
  }

  void _toggleNoteSelection(String noteId) {
    setState(() {
      if (_selectedNoteIds.contains(noteId)) {
        _selectedNoteIds.remove(noteId);
      } else {
        _selectedNoteIds.add(noteId);
      }
      if (_selectedNoteIds.isEmpty) {
        _isSelectionMode = false;
      }
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedNoteIds.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text("Recycle Bin"),
        automaticallyImplyLeading: true,
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.primary,
        elevation: 1,
        shadowColor: theme.colorScheme.shadow.withOpacity(0.2),
        centerTitle: true,
        leading: _buildAppBarLeading(),
        actions: _buildAppBarActions(context),
        titleTextStyle: theme.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.primary,
        ),
      ),
      body: FutureBuilder<Box<NoteTakingModel>>(
        future: HiveNoteTakingRepo.getDeletedBox(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ErrorApp(
              errorMessage: 'Error: ${snapshot.error}',
            );
          } else if (!snapshot.hasData || snapshot.data == null) {
            return const EmptyNotesMessage(
              message: 'Sorry Notes to delete',
              description: 'Go to notes and create some notes to delete',
            );
          } else {
            final box = snapshot.data!;

            return ValueListenableBuilder<Box<NoteTakingModel>>(
              valueListenable: box.listenable(),
              builder: (context, box, _) {
                if (box.values.isEmpty) {
                  return const EmptyNotesMessage(
                    message: 'Sorry Notes to delete',
                    description: 'Go to notes and create some notes to delete',
                  );
                }
                final notes = box.values.toList();

                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding:
                            const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Deleted Notes",
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            if (notes.isNotEmpty && !_isSelectionMode)
                              ElevatedButton(
                                onPressed: () {
                                  showConfirmationDialog(
                                    context,
                                    theme,
                                    () {
                                      NoteTakingActions
                                              .permanentlyDeleteAllNotes()
                                          .then((result) {
                                        CustomSnackBar.show(
                                            context, result.message);
                                      });
                                    },
                                    "Clear Recycle Bin",
                                    "Are you sure you want to Clear Recycle Bin?",
                                  );
                                },
                                child: const Text("Delete All"),
                              ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: MasonryGridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          mainAxisSpacing: 4,
                          crossAxisSpacing: 4,
                          itemCount: notes.length,
                          itemBuilder: (context, index) {
                            final note = notes[index];
                            return _buildNoteItem(note, context);
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }

  IconButton? _buildAppBarLeading() {
    return _isSelectionMode
        ? IconButton(
            icon: const Icon(LineIcons.check),
            onPressed: _exitSelectionMode,
          )
        : null;
  }

  List<Widget> _buildAppBarActions(BuildContext context) {
    if (_isSelectionMode) {
      return [
        IconButton(
          icon: const Icon(LineIcons.trash),
          onPressed: () {
            try {
              NoteTakingActions.permanentlyDeleteSelectedNotes(_selectedNoteIds)
                  .then((result) {
                CustomSnackBar.show(context, result.message);
                setState(() {});
              });
            } catch (e) {
              CustomSnackBar.show(context, e.toString());
            }
          },
        ),
        IconButton(
          icon: const Icon(Icons.restore),
          onPressed: () {
            try {
              NoteTakingActions.restoreSelectedNotes(_selectedNoteIds)
                  .then((result) {
                CustomSnackBar.show(context, result.message);
                setState(() {});
              });
            } catch (e) {
              CustomSnackBar.show(context, e.toString());
            }
          },
        ),
      ];
    }

    return const [];
  }

  Widget _buildNoteItem(NoteTakingModel note, BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (_isSelectionMode) {
          _toggleNoteSelection(note.noteId.toString());
        } else {}
      },
      onLongPress: () {
        if (!_isSelectionMode) {
          _enterSelectionMode(note.noteId.toString());
        }
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: _isSelectionMode &&
                  _selectedNoteIds.contains(note.noteId.toString())
              ? Theme.of(context).colorScheme.secondary.withOpacity(0.1)
              : null,
          border: _isSelectionMode &&
                  _selectedNoteIds.contains(note.noteId.toString())
              ? Border.all(
                  color: Theme.of(context).colorScheme.secondary, width: 2)
              : null,
        ),
        child: Card(
          elevation: 5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  note.noteTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  note.noteContent,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${DateTime.parse(note.updatedAt.toString()).day}/${DateTime.parse(note.updatedAt.toString()).month}/${DateTime.parse(note.updatedAt.toString()).year}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                    if (_isSelectionMode)
                      Checkbox(
                        value:
                            _selectedNoteIds.contains(note.noteId.toString()),
                        onChanged: (value) {
                          _toggleNoteSelection(note.noteId.toString());
                        },
                        activeColor: Theme.of(context).colorScheme.primary,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
