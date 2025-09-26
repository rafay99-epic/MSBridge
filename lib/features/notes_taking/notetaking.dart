import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bugfender/flutter_bugfender.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:line_icons/line_icons.dart';
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
import 'package:shared_preferences/shared_preferences.dart';
import 'package:msbridge/features/notes_taking/search/advanced_search_screen.dart';

enum NoteLayoutMode { grid, list }

enum NoteSortField { updatedAt, createdAt, tag }

enum NoteSortOrder { desc, asc }

class Notetaking extends StatefulWidget {
  const Notetaking({super.key});

  @override
  State<Notetaking> createState() => _NotetakingState();
}

class _NotetakingState extends State<Notetaking>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
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
  // Pin-related caches removed
  int _lastNotesCount = -1;
  DateTime? _lastLatestUpdate;

  // Layout preferences
  static const String _layoutPrefKey = 'note_layout_mode';
  NoteLayoutMode _layoutMode = NoteLayoutMode.grid;

  // Sort preferences
  static const String _sortFieldKey = 'note_sort_field';
  static const String _sortOrderKey = 'note_sort_order';
  NoteSortField _sortField = NoteSortField.updatedAt;
  NoteSortOrder _sortOrder = NoteSortOrder.desc;

  // Pin provider removed

  @override
  void initState() {
    super.initState();

    _loadLayoutPreference();
    _loadSortPreference();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNotes();
      _prewarmFabOverlay();
    });
  }

  @override
  void dispose() {
    _cachedNotes = null;
    super.dispose();
  }

  void _prewarmFabOverlay() {
    try {
      final OverlayState overlay = Overlay.of(context);
      final OverlayEntry entry = OverlayEntry(
        builder: (_) => Positioned.fill(
          child: IgnorePointer(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: const SizedBox.shrink(),
            ),
          ),
        ),
      );
      overlay.insert(entry);
      Future.delayed(const Duration(milliseconds: 48), () {
        try {
          entry.remove();
        } catch (e) {
          FlutterBugfender.sendCrash(
              "FAB blur prewarm failed: $e", StackTrace.current.toString());
        }
      });
    } catch (e) {
      FlutterBugfender.sendCrash(
          "FAB blur prewarm failed: $e", StackTrace.current.toString());
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
    } catch (e) {
      FlutterBugfender.error("Failed to load layout preference: $e");
      FlutterBugfender.sendCrash("Failed to load layout preference: $e",
          StackTrace.current.toString());
      if (!mounted) return;
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
      FlutterBugfender.log("Failed to save layout preference: $e");
      FlutterBugfender.sendCrash("Failed to save layout preference: $e",
          StackTrace.current.toString());
      FlutterBugfender.error("Failed to save layout preference: $e");
    }
  }

  Future<void> _loadSortPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final field = prefs.getString(_sortFieldKey);
      final order = prefs.getString(_sortOrderKey);
      if (mounted) {
        setState(() {
          _sortField = _parseSortField(field) ?? NoteSortField.updatedAt;
          _sortOrder = _parseSortOrder(order) ?? NoteSortOrder.desc;
        });
      }
    } catch (e) {
      FlutterBugfender.error("Failed to load sort preference: $e");
    }
  }

  Future<void> _saveSortPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_sortFieldKey, _sortField.name);
      await prefs.setString(_sortOrderKey, _sortOrder.name);
    } catch (e) {
      FlutterBugfender.error("Failed to save sort preference: $e");
    }
  }

  NoteSortField? _parseSortField(String? value) {
    switch (value) {
      case 'updatedAt':
        return NoteSortField.updatedAt;
      case 'createdAt':
        return NoteSortField.createdAt;
      case 'tag':
        return NoteSortField.tag;
    }
    return null;
  }

  NoteSortOrder? _parseSortOrder(String? value) {
    switch (value) {
      case 'asc':
        return NoteSortOrder.asc;
      case 'desc':
        return NoteSortOrder.desc;
    }
    return null;
  }

  Future<void> _loadNotes() async {
    if (_isLoading || _isDataLoaded) return;

    setState(() {
      _isLoading = true;
    });

    try {
      _notesListenable = await HiveNoteTakingRepo.getNotesListenable();

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
      FlutterBugfender.error("Failed to load notes: $e");
      FlutterBugfender.sendCrash(
          "Failed to load notes: $e", StackTrace.current.toString());
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _updateCachedNotes(Box<NoteTakingModel> box, {bool force = false}) {
    final values = box.values;
    final notesCount = values.length;
    DateTime? latestUpdate;
    for (final n in values) {
      if (latestUpdate == null || n.updatedAt.isAfter(latestUpdate)) {
        latestUpdate = n.updatedAt;
      }
    }
    if (!force &&
        notesCount == _lastNotesCount &&
        latestUpdate == _lastLatestUpdate) {
      return;
    }

    final notes = values.toList();
    _applySorting(notes);

    _cachedNotes = notes;
    _lastNotesCount = notesCount;
    _lastLatestUpdate = latestUpdate;
  }

  void _recomputeSorting() {
    final list = _notesListenable?.value;
    if (list != null) {
      _updateCachedNotes(list, force: true);
      if (mounted) setState(() {});
    }
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

    return DefaultTabController(
        length: 2,
        child: Scaffold(
          backgroundColor: theme.colorScheme.surface,
          appBar: AppBar(
            title: const Text("Note Taking"),
            automaticallyImplyLeading: false,
            backgroundColor: theme.colorScheme.surface,
            foregroundColor: theme.colorScheme.primary,
            elevation: 1,
            shadowColor: theme.colorScheme.shadow.withOpacity(0.2),
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.settings),
              onPressed: _openSettingsSheet,
              tooltip: 'Settings',
            ),
            actions: _buildAppBarActions(),
            titleTextStyle: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary,
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: TabBar(
                    dividerColor: Colors.transparent,
                    splashFactory: NoSplash.splashFactory,
                    overlayColor: const MaterialStatePropertyAll<Color>(
                        Colors.transparent),
                    indicator: UnderlineTabIndicator(
                      borderSide: BorderSide(
                        color: theme.colorScheme.primary.withOpacity(0.8),
                        width: 3,
                      ),
                      insets: const EdgeInsets.symmetric(horizontal: 24),
                    ),
                    indicatorSize: TabBarIndicatorSize.label,
                    labelColor: theme.colorScheme.primary,
                    unselectedLabelColor:
                        theme.colorScheme.primary.withOpacity(0.55),
                    labelStyle: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                    tabs: const [
                      Tab(text: 'Notes'),
                      Tab(text: 'Folders'),
                    ],
                  ),
                ),
              ),
            ),
          ),
          body: TabBarView(
            physics: const BouncingScrollPhysics(),
            children: [
              _KeepAlive(child: _buildBody(theme)),
              const _KeepAlive(child: FoldersPage()),
            ],
          ),
          floatingActionButtonLocation: ExpandableFab.location,
          floatingActionButton: _showFab ? _buildExpandableFab(theme) : null,
        ));
  }

  Widget _buildBody(ThemeData theme) {
    // Show optimized loading state
    if (_isLoading || !_isDataLoaded || _notesListenable == null) {
      return _buildLoadingState(theme);
    }

    return ValueListenableBuilder<Box<NoteTakingModel>>(
      valueListenable: _notesListenable!,
      builder: (context, box, _) {
        _updateCachedNotes(box);

        if (box.values.isEmpty) {
          return const Center(
            child: EmptyNotesMessage(
              message: 'No notes yet',
              description: 'Tap + to create a new note',
            ),
          );
        }
        return _buildNotesList(theme);
      },
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
    final notes = _cachedNotes ?? [];

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      cacheExtent: 1000,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(8.0, 20.0, 8.0, 28.0),
          sliver: SliverMasonryGrid.count(
            crossAxisCount: _layoutMode == NoteLayoutMode.grid ? 2 : 1,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childCount: notes.length,
            itemBuilder: (context, index) {
              final note = notes[index];
              return _buildNoteItem(note, context);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNoteItem(NoteTakingModel note, BuildContext context) {
    return RepaintBoundary(
      child: GestureDetector(
        onTap: () async {
          if (_isSelectionMode) {
            if (note.noteId != null) {
              _toggleNoteSelection(note.noteId!);
            }
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
          if (!_isSelectionMode && note.noteId != null) {
            _enterSelectionMode(note.noteId!);
          }
        },
        child: NoteCard(
          note: note,
          isSelected:
              note.noteId != null && _selectedNoteIds.contains(note.noteId!),
          isSelectionMode: _isSelectionMode,
          isGridLayout: _layoutMode == NoteLayoutMode.grid,
        ),
      ),
    );
  }

  // Old leading kept for reference; no longer used after tabs

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

  void _openSortBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('Sort by',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(color: theme.colorScheme.primary)),
              ),
              RadioListTile<NoteSortField>(
                value: NoteSortField.updatedAt,
                groupValue: _sortField,
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _sortField = v);
                  _saveSortPreference();
                  _recomputeSorting();
                  Navigator.pop(ctx);
                },
                title: const Text('Last updated'),
              ),
              RadioListTile<NoteSortField>(
                value: NoteSortField.createdAt,
                groupValue: _sortField,
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _sortField = v);
                  _saveSortPreference();
                  _recomputeSorting();
                  Navigator.pop(ctx);
                },
                title: const Text('Date created'),
              ),
              RadioListTile<NoteSortField>(
                value: NoteSortField.tag,
                groupValue: _sortField,
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _sortField = v);
                  _saveSortPreference();
                  _recomputeSorting();
                  Navigator.pop(ctx);
                },
                title: const Text('Tag (A→Z)'),
              ),
              const Divider(height: 8),
              ListTile(
                title: Text('Order',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(color: theme.colorScheme.primary)),
              ),
              RadioListTile<NoteSortOrder>(
                value: NoteSortOrder.desc,
                groupValue: _sortOrder,
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _sortOrder = v);
                  _saveSortPreference();
                  _recomputeSorting();
                  Navigator.pop(ctx);
                },
                title: const Text('Descending'),
              ),
              RadioListTile<NoteSortOrder>(
                value: NoteSortOrder.asc,
                groupValue: _sortOrder,
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _sortOrder = v);
                  _saveSortPreference();
                  _recomputeSorting();
                  Navigator.pop(ctx);
                },
                title: const Text('Ascending'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _openSettingsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.sort),
                title: const Text('Sort Notes'),
                onTap: () {
                  Navigator.pop(ctx);
                  _openSortBottomSheet();
                },
              ),
              ListTile(
                leading: const Icon(Icons.dashboard_customize_outlined),
                title: const Text('Arrange View (Layout)'),
                onTap: () {
                  Navigator.pop(ctx);
                  _toggleLayoutMode();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _applySorting(List<NoteTakingModel> list) {
    int cmp(NoteTakingModel a, NoteTakingModel b) {
      int result;
      switch (_sortField) {
        case NoteSortField.updatedAt:
          result = a.updatedAt.compareTo(b.updatedAt);
          break;
        case NoteSortField.createdAt:
          result = a.createdAt.compareTo(b.createdAt);
          break;
        case NoteSortField.tag:
          final at = (a.tags.isNotEmpty ? a.tags.first : '').toLowerCase();
          final bt = (b.tags.isNotEmpty ? b.tags.first : '').toLowerCase();
          result = at.compareTo(bt);
          if (result == 0) {
            result = a.updatedAt.compareTo(b.updatedAt);
          }
          break;
      }
      return _sortOrder == NoteSortOrder.asc ? result : -result;
    }

    list.sort(cmp);
  }

  Widget _buildExpandableFab(ThemeData theme) {
    return ExpandableFab(
      type: ExpandableFabType.up,
      childrenAnimation: ExpandableFabAnimation.rotate,
      distance: 70,
      overlayStyle: ExpandableFabOverlayStyle(
        color: Colors.black.withOpacity(0.5),
        blur: 12,
      ),
      children: [
        buildExpandableButton(
          context: context,
          heroTag: "Add New Note",
          icon: Icons.note,
          text: "Text Note",
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

class _KeepAlive extends StatefulWidget {
  final Widget child;
  const _KeepAlive({required this.child});
  @override
  State<_KeepAlive> createState() => _KeepAliveState();
}

class _KeepAliveState extends State<_KeepAlive>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
