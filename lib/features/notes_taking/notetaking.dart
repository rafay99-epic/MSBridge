import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:line_icons/line_icons.dart';
import 'package:msbridge/core/provider/pin_note_provider.dart';
import 'package:msbridge/core/repo/hive_note_taking_repo.dart';
import 'package:msbridge/core/repo/note_taking_actions_repo.dart';
import 'package:msbridge/core/database/note_taking/note_taking.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:msbridge/features/notes_taking/create/create_note.dart';
import 'package:msbridge/features/todo/to_do.dart';
import 'package:msbridge/utils/empty_ui.dart';
import 'package:msbridge/utils/error.dart';
import 'package:msbridge/features/notes_taking/widget/note_taking_card.dart';
import 'package:msbridge/widgets/floatting_button.dart';
import 'package:msbridge/widgets/snakbar.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum NoteLayoutMode { grid, list }

class Notetaking extends StatefulWidget {
  const Notetaking({super.key});

  @override
  State<Notetaking> createState() => _NotetakingState();
}

class _NotetakingState extends State<Notetaking>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  bool _isSelectionMode = false;
  final List<String> _selectedNoteIds = [];
  bool _isSearching = false;

  String _lowerCaseSearchQuery = '';

  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  ValueListenable<Box<NoteTakingModel>>? notesListenable;
  static const String _layoutPrefKey = 'note_layout_mode';
  NoteLayoutMode _layoutMode = NoteLayoutMode.grid;

  @override
  void initState() {
    super.initState();
    _loadNotes();
    _loadLayoutPreference();
  }

  Future<void> _loadNotes() async {
    try {
      notesListenable = await HiveNoteTakingRepo.getNotesListenable();
      setState(() {});
    } catch (e) {
      if (kDebugMode) {
        print("Failed to cache: $e");
      }
    }
  }

  Future<void> _loadLayoutPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_layoutPrefKey);
      if (saved == 'list') {
        setState(() {
          _layoutMode = NoteLayoutMode.list;
        });
      } else if (saved == 'grid') {
        setState(() {
          _layoutMode = NoteLayoutMode.grid;
        });
      }
    } catch (_) {}
  }

  Future<void> _saveLayoutPreference(NoteLayoutMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _layoutPrefKey, mode == NoteLayoutMode.grid ? 'grid' : 'list');
    } catch (_) {}
  }

  void _toggleLayoutMode() {
    setState(() {
      _layoutMode = _layoutMode == NoteLayoutMode.grid
          ? NoteLayoutMode.list
          : NoteLayoutMode.grid;
    });
    _saveLayoutPreference(_layoutMode);
  }

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

  Future<void> _deleteSelectedNotes() async {
    if (_selectedNoteIds.isNotEmpty) {
      final result =
          await NoteTakingActions.deleteSelectedNotes(_selectedNoteIds);

      if (result.success) {
        CustomSnackBar.show(context, result.message);
      } else {
        CustomSnackBar.show(context, result.message);
      }

      _exitSelectionMode();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: _buildAppBarTitle(theme),
        automaticallyImplyLeading: false,
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
      body: ChangeNotifierProvider(
        create: (context) {
          final noteProvider = NoteePinProvider();
          noteProvider.initialize();
          return noteProvider;
        },
        child: Consumer<NoteePinProvider>(
          builder: (context, noteProvider, _) {
            return FutureBuilder<ValueListenable<Box<NoteTakingModel>>>(
              future: HiveNoteTakingRepo.getNotesListenable(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return ErrorApp(
                    errorMessage: 'Error: ${snapshot.error}',
                  );
                } else if (!snapshot.hasData) {
                  return const EmptyNotesMessage(
                    message: 'Sorry Notes ',
                    description: 'Tap + to create a new note',
                  );
                } else {
                  final notesListenable = snapshot.data!;

                  return ValueListenableBuilder<Box<NoteTakingModel>>(
                    valueListenable: notesListenable,
                    builder: (context, box, _) {
                      if (box.values.isEmpty) {
                        return const EmptyNotesMessage(
                          message: 'Sorry Notes ',
                          description: 'Tap + to create a new note',
                        );
                      }

                      final notes = box.values.toList();

                      final pinnedNotes = notes
                          .where((note) =>
                              noteProvider.isNotePinned(note.noteId.toString()))
                          .where((note) => _matchesSearchQuery(note))
                          .toList();
                      final unpinnedNotes = notes
                          .where((note) => !noteProvider
                              .isNotePinned(note.noteId.toString()))
                          .where((note) => _matchesSearchQuery(note))
                          .toList();

                      return SingleChildScrollView(
                        padding: const EdgeInsets.only(bottom: 28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (pinnedNotes.isNotEmpty) ...[
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                    16.0, 16.0, 16.0, 8.0),
                                child: Text(
                                  "Pinned Notes",
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8.0),
                                child: MasonryGridView.count(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  crossAxisCount: _layoutMode == NoteLayoutMode.grid ? 2 : 1,
                                  mainAxisSpacing: 10,
                                  crossAxisSpacing: 10,
                                  itemCount: pinnedNotes.length,
                                  itemBuilder: (context, index) {
                                    final note = pinnedNotes[index];
                                    return _buildNoteItem(note, context);
                                  },
                                ),
                              ),
                            ],
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                  16.0, 16.0, 16.0, 8.0),
                              child: Text(
                                " Notes",
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8.0),
                              child: MasonryGridView.count(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                crossAxisCount: _layoutMode == NoteLayoutMode.grid ? 2 : 1,
                                mainAxisSpacing: 10,
                                crossAxisSpacing: 10,
                                itemCount: unpinnedNotes.length,
                                itemBuilder: (context, index) {
                                  final note = unpinnedNotes[index];
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
            );
          },
        ),
      ),
      floatingActionButtonLocation: ExpandableFab.location,
      floatingActionButton: ExpandableFab(
        type: ExpandableFabType.up,
        childrenAnimation: ExpandableFabAnimation.rotate,
        distance: 100,
        overlayStyle: ExpandableFabOverlayStyle(
          color: theme.colorScheme.surface.withOpacity(0.7),
          blur: 2,
        ),
        children: [
          buildExpandableButton(
            context: context,
            heroTag: "Add New Note",
            icon: Icons.note,
            text: "New Note",
            theme: theme,
            onPressed: () async {
              await Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      const CreateNote(),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  transitionDuration: const Duration(milliseconds: 300),
                ),
              );
            },
          ),
          buildExpandableButton(
            context: context,
            heroTag: "To-Do List",
            icon: Icons.check,
            text: "New To-Do",
            theme: theme,
            onPressed: () async {
              await Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      const ToDO(), // or TaskEntryScreen, whichever is correct
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  transitionDuration: const Duration(milliseconds: 300),
                ),
              );
            },
          ),
        ],
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
              hintText: 'Search notes...',
              hintStyle:
                  TextStyle(color: theme.colorScheme.primary.withOpacity(0.6)),
              border: InputBorder.none,
            ),
            onChanged: (query) {
              _onSearchChanged(query);
            },
          )
        : const Text("Note Taking");
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
    return _isSelectionMode
        ? [
            IconButton(
              icon: const Icon(LineIcons.trash),
              onPressed: _deleteSelectedNotes,
            ),
          ]
        : [
            IconButton(
              icon: const Icon(LineIcons.search),
              onPressed: _enterSearch,
            ),
            IconButton(
              tooltip: 'Switch layout',
              icon: Icon(
                _layoutMode == NoteLayoutMode.grid
                    ? Icons.view_agenda_outlined
                    : Icons.grid_view,
              ),
              onPressed: _toggleLayoutMode,
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
      onTap: () async {
        if (_isSelectionMode) {
          _toggleNoteSelection(note.noteId.toString());
        } else {
          await Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  CreateNote(
                note: note,
              ),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
              transitionDuration: const Duration(milliseconds: 300),
            ),
          );
        }
      },
      onLongPress: () {
        if (!_isSelectionMode) {
          _enterSelectionMode(note.noteId.toString());
        }
      },
      child: NoteCard(
        note: note,
        isSelected: _selectedNoteIds.contains(note.noteId.toString()),
        isSelectionMode: _isSelectionMode,
      ),
    );
  }
}
