import 'dart:async';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bugfender/flutter_bugfender.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:line_icons/line_icons.dart';
import 'package:msbridge/core/provider/pin_note_provider.dart';
import 'package:msbridge/core/repo/hive_note_taking_repo.dart';
import 'package:msbridge/core/repo/note_taking_actions_repo.dart';
import 'package:msbridge/core/database/note_taking/note_taking.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:msbridge/features/notes_taking/create/create_note.dart';
import 'package:msbridge/features/notes_taking/folders/folders_page.dart';
import 'package:msbridge/features/todo/to_do.dart';
import 'package:msbridge/utils/empty_ui.dart';
import 'package:msbridge/features/notes_taking/widget/note_taking_card.dart';
import 'package:msbridge/widgets/floatting_button.dart';
import 'package:msbridge/widgets/snakbar.dart';
import 'package:page_transition/page_transition.dart';
import 'package:msbridge/features/templates/templates_hub.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:msbridge/features/notes_taking/search/advanced_search_screen.dart';

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

  // Performance optimization flags
  bool _isDataLoaded = false;
  bool _isLoading = false;
  final bool _showFab = true;

  // Selection state
  bool _isSelectionMode = false;
  final List<String> _selectedNoteIds = [];

  // Cached data
  ValueListenable<Box<NoteTakingModel>>? _notesListenable;
  List<NoteTakingModel>? _cachedNotes;
  List<NoteTakingModel>? _cachedPinnedNotes;
  List<NoteTakingModel>? _cachedUnpinnedNotes;

  // Layout preferences
  static const String _layoutPrefKey = 'note_layout_mode';
  NoteLayoutMode _layoutMode = NoteLayoutMode.grid;

  // Providers
  NoteePinProvider? _pinProvider;

  @override
  void initState() {
    super.initState();

    // Initialize pin provider early
    _pinProvider = NoteePinProvider();
    _pinProvider!.initialize();

    // Load layout preference immediately
    _loadLayoutPreference();

    // Defer data loading to prevent jank during initial render
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNotes();
    });
  }

  @override
   @override
   void dispose() {
     _pinProvider?.dispose();
     _pinProvider = null;
     _cachedNotes = null;
     _cachedPinnedNotes = null;
     _cachedUnpinnedNotes = null;
     super.dispose();
   }
  }

  Future<void> _loadLayoutPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_layoutPrefKey);
      if (saved == 'list' && mounted) {
        setState(() {
          _layoutMode = NoteLayoutMode.list;
        });
      }
    } catch (_) {
      // Fallback to default grid layout
      setState(() {
        _layoutMode = NoteLayoutMode.grid;
      });
    }
  }

  Future<void> _saveLayoutPreference(NoteLayoutMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _layoutPrefKey, mode == NoteLayoutMode.grid ? 'grid' : 'list');
    } catch (e) {
      // Silently fail if preferences can't be saved
      FlutterBugfender.log("Failed to save layout preference: $e");
      FirebaseCrashlytics.instance.recordError(e, StackTrace.current,
          reason: 'Failed to save layout preference');
    }
  }

  Future<void> _loadNotes() async {
    if (_isLoading || _isDataLoaded) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Get notes listenable
      _notesListenable = await HiveNoteTakingRepo.getNotesListenable();

      // Pre-cache notes for faster initial render
      if (_notesListenable != null) {
        _updateCachedNotes(_notesListenable!.value);
      }

      if (mounted) {
        setState(() {
          _isDataLoaded = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      if (kDebugMode) {
        print("Failed to load notes: $e");
      }
    }
  }

  // Update cached notes when data changes
  void _updateCachedNotes(Box<NoteTakingModel> box) {
    if (_pinProvider == null) return;

    final notes = box.values.toList();

    // Split into pinned and unpinned notes
    final pinnedNotes = notes
        .where((note) => _pinProvider!.isNotePinned(note.noteId.toString()))
        .toList();
    final unpinnedNotes = notes
        .where((note) => !_pinProvider!.isNotePinned(note.noteId.toString()))
        .toList();

    _cachedNotes = notes;
    _cachedPinnedNotes = pinnedNotes;
    _cachedUnpinnedNotes = unpinnedNotes;
  }

  void _toggleLayoutMode() {
    setState(() {
      _layoutMode = _layoutMode == NoteLayoutMode.grid
          ? NoteLayoutMode.list
          : NoteLayoutMode.grid;
    });
    _saveLayoutPreference(_layoutMode);
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
    if (_selectedNoteIds.isEmpty) return;

    final result =
        await NoteTakingActions.deleteSelectedNotes(_selectedNoteIds);

    if (mounted) {
      CustomSnackBar.show(context, result.message, isSuccess: result.success);

      _exitSelectionMode();
    }
  }

  void _enterSearch() {
    final currentNotes = _cachedNotes ?? [];
    FlutterBugfender.log("Entering search with ${currentNotes.length} notes");
    Navigator.push(
      context,
      PageTransition(
        child: AdvancedSearchScreen(
          takingNotes: currentNotes,
          readingNotes: [],
          searchReadingNotes: false,
        ),
        type: PageTransitionType.bottomToTop,
        duration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text("Note Taking"),
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
      body: _buildBody(theme),
      floatingActionButtonLocation: ExpandableFab.location,
      floatingActionButton: _showFab ? _buildExpandableFab(theme) : null,
    );
  }

  Widget _buildBody(ThemeData theme) {
    // Show optimized loading state
    if (_isLoading || !_isDataLoaded || _notesListenable == null) {
      return _buildLoadingState(theme);
    }

    // Provide pin provider to descendants
    return ChangeNotifierProvider.value(
      value: _pinProvider,
      child: ValueListenableBuilder<Box<NoteTakingModel>>(
        valueListenable: _notesListenable!,
        builder: (context, box, _) {
          // Update cached notes when box changes
          _updateCachedNotes(box);

          if (box.values.isEmpty) {
            return const EmptyNotesMessage(
              message: 'Sorry Notes ',
              description: 'Tap + to create a new note',
            );
          }

          return _buildNotesList(theme);
        },
      ),
    );
  }

  Widget _buildLoadingState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading notes...',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesList(ThemeData theme) {
    final pinnedNotes = _cachedPinnedNotes ?? [];
    final unpinnedNotes = _cachedUnpinnedNotes ?? [];

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Pinned notes section
        if (pinnedNotes.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
              child: Text(
                "Pinned Notes",
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            sliver: SliverMasonryGrid.count(
              crossAxisCount: _layoutMode == NoteLayoutMode.grid ? 2 : 1,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childCount: pinnedNotes.length,
              itemBuilder: (context, index) {
                final note = pinnedNotes[index];
                return _buildNoteItem(note, context);
              },
            ),
          ),
        ],

        // Unpinned notes section
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
            child: Text(
              " Notes",
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(8.0, 0.0, 8.0, 28.0),
          sliver: SliverMasonryGrid.count(
            crossAxisCount: _layoutMode == NoteLayoutMode.grid ? 2 : 1,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childCount: unpinnedNotes.length,
            itemBuilder: (context, index) {
              final note = unpinnedNotes[index];
              return _buildNoteItem(note, context);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNoteItem(NoteTakingModel note, BuildContext context) {
    // Use RepaintBoundary to isolate painting operations
    return RepaintBoundary(
      child: GestureDetector(
        onTap: () async {
          if (_isSelectionMode) {
            _toggleNoteSelection(note.noteId.toString());
          } else {
            await Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    CreateNote(note: note),
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
          isGridLayout: _layoutMode == NoteLayoutMode.grid,
        ),
      ),
    );
  }

  IconButton? _buildAppBarLeading() {
    return IconButton(
      icon: Icon(_isSelectionMode ? LineIcons.check : LineIcons.folder),
      onPressed: _isSelectionMode
          ? _exitSelectionMode
          : () {
              Navigator.push(
                context,
                PageTransition(
                  child: const FoldersPage(),
                  type: PageTransitionType.rightToLeft,
                  duration: const Duration(milliseconds: 300),
                ),
              );
            },
      tooltip: _isSelectionMode ? 'Exit selection mode' : 'Folders',
    );
  }

  List<Widget> _buildAppBarActions() {
    return _isSelectionMode
        ? [
            IconButton(
              icon: const Icon(LineIcons.trash),
              onPressed: _deleteSelectedNotes,
              tooltip: 'Delete selected notes',
            ),
          ]
        : [
            IconButton(
              icon: const Icon(LineIcons.search),
              onPressed: _enterSearch,
              tooltip: 'Search notes',
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

  Widget _buildExpandableFab(ThemeData theme) {
    return ExpandableFab(
      type: ExpandableFabType.up,
      childrenAnimation: ExpandableFabAnimation.rotate,
      distance: 80,
      overlayStyle: ExpandableFabOverlayStyle(
        color: theme.colorScheme.surface.withOpacity(0.5),
        blur: 1,
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
          heroTag: "Templates",
          icon: Icons.description,
          text: "Templates",
          theme: theme,
          onPressed: () async {
            await Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    const TemplatesHubPage(),
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
                    const ToDO(),
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
    );
  }
}
