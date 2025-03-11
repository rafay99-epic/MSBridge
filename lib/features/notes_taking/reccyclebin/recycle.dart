import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:line_icons/line_icons.dart';
import 'package:msbridge/core/repo/hive_note_taking_repo.dart';
import 'package:msbridge/core/database/note_taking/note_taking.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:msbridge/utils/empty_ui.dart';
import 'package:msbridge/utils/error.dart';
import 'package:msbridge/widgets/snakbar.dart';

class DeletedNotes extends StatefulWidget {
  const DeletedNotes({super.key});

  @override
  State<DeletedNotes> createState() => _DeletedNotesState();
}

class _DeletedNotesState extends State<DeletedNotes> {
  bool _isSelectionMode = false;
  final List<String> _selectedNoteIds = [];
  bool _isSearching = false;
  String _lowerCaseSearchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

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

  Future<void> _permanentlyDeleteSelectedNotes() async {
    if (_selectedNoteIds.isNotEmpty) {
      try {
        final box = await HiveNoteTakingRepo.getDeletedBox();
        for (final noteId in _selectedNoteIds) {
          final noteToDelete = box.values.firstWhere(
            (note) => note.noteId == noteId,
            orElse: () => NoteTakingModel(
                noteId: '',
                noteTitle: '',
                noteContent: '',
                isSynced: false,
                isDeleted: false,
                updatedAt: DateTime.now(),
                userId: ''),
          );

          await HiveNoteTakingRepo.permantentlydeleteNote(noteToDelete);
        }
        CustomSnackBar.show(context, "Selected notes permanently deleted.");
      } catch (e) {
        CustomSnackBar.show(context, "Error deleting notes: $e");
        print("⚠️Error deleting notes: $e");
      }
      _exitSelectionMode();
      setState(() {});
    }
  }

  Future<void> _permanentlyDeleteAllNotes() async {
    try {
      final box = await HiveNoteTakingRepo.getDeletedBox();

      final allNotes = box.values.toList();
      for (final note in allNotes) {
        await HiveNoteTakingRepo.permantentlydeleteNote(note);
      }
      CustomSnackBar.show(context, "All notes permanently deleted.");
    } catch (e) {
      CustomSnackBar.show(context, "Error deleting all notes: $e");
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: _buildAppBarTitle(theme),
        automaticallyImplyLeading: true,
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.primary,
        elevation: 1,
        shadowColor: theme.colorScheme.shadow.withOpacity(0.2),
        centerTitle: true,
        leading: _buildAppBarLeading(),
        actions: _buildAppBarActions(),
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
              message: 'Soory Notes to delete',
              description: 'Go to notes and create some notes to delete',
            );
          } else {
            final box = snapshot.data!;

            return ValueListenableBuilder<Box<NoteTakingModel>>(
              valueListenable: box.listenable(),
              builder: (context, box, _) {
                if (box.values.isEmpty) {
                  return const EmptyNotesMessage(
                    message: 'Soory Notes to delete',
                    description: 'Go to notes and create some notes to delete',
                  );
                }
                final notes = box.values
                    .where((note) => _matchesSearchQuery(note))
                    .toList();

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
                                onPressed: _permanentlyDeleteAllNotes,
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

  Widget _buildAppBarTitle(ThemeData theme) {
    return _isSearching
        ? TextField(
            controller: _searchController,
            autofocus: true,
            style: TextStyle(color: theme.colorScheme.primary),
            decoration: InputDecoration(
              hintText: 'Search deleted notes...',
              hintStyle:
                  TextStyle(color: theme.colorScheme.primary.withOpacity(0.6)),
              border: InputBorder.none,
            ),
            onChanged: (query) {
              _onSearchChanged(query);
            },
          )
        : const Text("Recycle Bin");
  }

  IconButton? _buildAppBarLeading() {
    return _isSelectionMode
        ? IconButton(
            icon: const Icon(LineIcons.check),
            onPressed: _exitSelectionMode,
          )
        : _isSearching
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _exitSearch,
              )
            : null;
  }

  List<Widget> _buildAppBarActions() {
    if (_isSelectionMode) {
      return [
        IconButton(
          icon: const Icon(LineIcons.trash),
          onPressed: _permanentlyDeleteSelectedNotes,
        ),
      ];
    }

    return [
      if (!_isSearching)
        IconButton(
          icon: const Icon(LineIcons.search),
          onPressed: _enterSearch,
        ),
    ];
  }

  void _enterSearch() {
    setState(() {
      _isSearching = true;
    });
  }

  void _exitSearch() {
    setState(() {
      _isSearching = false;
      _searchController.clear();
      _lowerCaseSearchQuery = '';
    });
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      final lowerCaseQuery = query.toLowerCase();
      setState(() {
        _lowerCaseSearchQuery = lowerCaseQuery;
      });
    });
  }

  bool _matchesSearchQuery(NoteTakingModel note) {
    return note.noteTitle.toLowerCase().contains(_lowerCaseSearchQuery) ||
        note.noteContent.toLowerCase().contains(_lowerCaseSearchQuery);
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
