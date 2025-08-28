import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:msbridge/core/database/note_taking/note_taking.dart';
import 'package:msbridge/core/services/advance_search/advanced_note_search_service.dart';
import 'package:msbridge/features/notes_taking/create/create_note.dart';
import 'package:page_transition/page_transition.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';

class AdvancedSearchScreen extends StatefulWidget {
  final List<NoteTakingModel> allNotes;

  const AdvancedSearchScreen({
    super.key,
    required this.allNotes,
  });

  @override
  State<AdvancedSearchScreen> createState() => _AdvancedSearchScreenState();
}

class _AdvancedSearchScreenState extends State<AdvancedSearchScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  String _searchQuery = '';
  List<NoteSearchResult> _searchResults = [];
  List<String> searchSuggestions = [];
  bool _isSearching = false;
  bool _showFilters = false;
  bool _isLoadingResults = false; // Add loading state

  // Filter states
  DateTime? _fromDate;
  DateTime? _toDate;
  List<String> _selectedTags = [];
  bool includeDeleted = false;

  // Available tags from all notes
  List<String> _availableTags = const [];

  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    // Extract tags lazily to avoid blocking the UI
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _extractAvailableTags();
      _animationController.forward();
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _animationController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _extractAvailableTags() {
    try {
      // Convert Hive objects to simple data structures before background processing
      final simpleNotes = widget.allNotes
          .map((note) => {
                'noteId': note.noteId,
                'noteTitle': note.noteTitle,
                'noteContent': note.noteContent,
                'tags': note.tags,
                'createdAt': note.createdAt.toIso8601String(),
                'updatedAt': note.updatedAt.toIso8601String(),
                'isDeleted': note.isDeleted,
              })
          .toList();

      // Use compute to run tag extraction in background
      compute(_extractTagsInBackground, simpleNotes).then((tags) {
        if (mounted) {
          setState(() {
            _availableTags = tags;
          });
        }
      }).catchError((error) {
        // Fallback to main thread if background processing fails
        if (mounted) {
          _extractTagsInMainThread();
        }
      });
    } catch (e) {
      // Fallback to main thread if conversion fails
      _extractTagsInMainThread();
    }
  }

  void _extractTagsInMainThread() {
    final Set<String> tags = {};
    for (final note in widget.allNotes) {
      if (note.tags.isNotEmpty) {
        tags.addAll(note.tags);
      }
    }
    if (mounted) {
      setState(() {
        _availableTags = tags.toList()..sort();
      });
    }
  }

  static List<String> _extractTagsInBackground(
      List<Map<String, dynamic>> simpleNotes) {
    final Set<String> tags = {};
    for (final note in simpleNotes) {
      final noteTags = note['tags'] as List<String>?;
      if (noteTags != null && noteTags.isNotEmpty) {
        tags.addAll(noteTags);
      }
    }
    return tags.toList()..sort();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _isSearching = query.isNotEmpty;
    });

    if (query.isEmpty) {
      _clearSearch();
      return;
    }

    // Debounce search to improve performance
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        // Get search suggestions (keep in main thread to avoid isolate issues)
        searchSuggestions = AdvancedNoteSearchService.getSearchSuggestions(
          widget.allNotes,
          query,
        );

        // Process search in background
        _performSearchInBackground();
      }
    });
  }

  void _performSearchInBackground() {
    try {
      // Show loading indicator
      setState(() {
        _searchResults = [];
        _isLoadingResults = true;
      });

      // Convert Hive objects to simple data structures
      final simpleNotes = widget.allNotes
          .map((note) => {
                'noteId': note.noteId,
                'noteTitle': note.noteTitle,
                'noteContent': note.noteContent,
                'tags': note.tags,
                'createdAt': note.createdAt.toIso8601String(),
                'updatedAt': note.updatedAt.toIso8601String(),
                'isDeleted': note.isDeleted,
                'isSynced': note.isSynced,
                'userId': note.userId,
                'versionNumber': note.versionNumber,
              })
          .toList();

      // Process search in background
      compute(_processSearchInBackground, {
        'notes': simpleNotes,
        'query': _searchQuery,
        'fromDate': _fromDate?.toIso8601String(),
        'toDate': _toDate?.toIso8601String(),
        'tags': _selectedTags.isNotEmpty ? _selectedTags : null,
        'includeDeleted': includeDeleted,
      }).then((results) {
        if (mounted) {
          setState(() {
            _searchResults = results;
            _isLoadingResults = false;
          });
        }
      }).catchError((error) {
        // Fallback to main thread if background processing fails
        if (mounted) {
          _performSearchInMainThread();
        }
      });
    } catch (e) {
      // Fallback to main thread if conversion fails
      _performSearchInMainThread();
    }
  }

  void _performSearchInMainThread() {
    try {
      final results = AdvancedNoteSearchService.searchNotes(
        notes: widget.allNotes,
        query: _searchQuery,
        fromDate: _fromDate,
        toDate: _toDate,
        tags: _selectedTags.isNotEmpty ? _selectedTags : null,
        includeDeleted: includeDeleted,
      );

      if (mounted) {
        setState(() {
          _searchResults = results;
          _isLoadingResults = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _searchResults = [];
          _isLoadingResults = false;
        });
      }
    }
  }

  static List<NoteSearchResult> _processSearchInBackground(
      Map<String, dynamic> params) {
    final simpleNotes = params['notes'] as List<Map<String, dynamic>>;
    final query = params['query'] as String;
    final fromDateStr = params['fromDate'] as String?;
    final toDateStr = params['toDate'] as String?;
    final tags = params['tags'] as List<String>?;
    final includeDeleted = params['includeDeleted'] as bool;

    // Convert simple data back to NoteTakingModel for search
    final notes = simpleNotes
        .map((simpleNote) => NoteTakingModel(
              noteId: simpleNote['noteId'] as String?,
              noteTitle: simpleNote['noteTitle'] as String,
              noteContent: simpleNote['noteContent'] as String,
              tags: (simpleNote['tags'] as List<dynamic>).cast<String>(),
              createdAt: simpleNote['createdAt'] != null
                  ? DateTime.parse(simpleNote['createdAt'] as String)
                  : null,
              updatedAt: DateTime.parse(simpleNote['updatedAt'] as String),
              isDeleted: simpleNote['isDeleted'] as bool,
              isSynced: simpleNote['isSynced'] as bool,
              userId: simpleNote['userId'] as String,
              versionNumber: simpleNote['versionNumber'] as int,
            ))
        .toList();

    // Parse dates
    final fromDate = fromDateStr != null ? DateTime.parse(fromDateStr) : null;
    final toDate = toDateStr != null ? DateTime.parse(toDateStr) : null;

    return AdvancedNoteSearchService.searchNotes(
      notes: notes,
      query: query,
      fromDate: fromDate,
      toDate: toDate,
      tags: tags,
      includeDeleted: includeDeleted,
    );
  }

  void _performSearch() {
    // Use background processing for better performance
    _performSearchInBackground();
  }

  void _clearSearch() {
    setState(() {
      _searchQuery = '';
      _searchResults = [];
      searchSuggestions = [];
      _isSearching = false;
    });
    _searchController.clear();
  }

  void _toggleFilters() {
    setState(() {
      _showFilters = !_showFilters;
    });
  }

  void _selectDateRange() async {
    final DateTimeRange? picked = await showModalBottomSheet<DateTimeRange>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _CustomDateRangePicker(
        fromDate: _fromDate,
        toDate: _toDate,
        theme: Theme.of(context),
        onDateRangeSelected: (range) {
          setState(() {
            _fromDate = range.start;
            _toDate = range.end;
          });
          _performSearch();
        },
      ),
    );

    if (picked != null) {
      setState(() {
        _fromDate = picked.start;
        _toDate = picked.end;
      });
      _performSearch();
    }
  }

  void _clearAllFilters() {
    setState(() {
      _fromDate = null;
      _toDate = null;
      _selectedTags.clear();
      includeDeleted = false;
    });
    _performSearch();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: _buildSearchField(theme),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.primary,
        elevation: 0,
        actions: [
          if (_isSearching)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: _clearSearch,
              tooltip: 'Clear search',
            ),
          IconButton(
            icon: Icon(
                _showFilters ? Icons.filter_list : Icons.filter_list_outlined),
            onPressed: _toggleFilters,
            tooltip: 'Toggle filters',
          ),
        ],
        bottom: _showFilters ? _buildFilterBar(theme) : null,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: _buildBody(theme),
        ),
      ),
    );
  }

  Widget _buildSearchField(ThemeData theme) {
    return TextField(
      controller: _searchController,
      focusNode: _searchFocusNode,
      style: TextStyle(
        color: theme.colorScheme.primary,
        fontSize: 18,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: 'Search notes, tags, or content...',
        hintStyle: TextStyle(
          color: theme.colorScheme.primary.withOpacity(0.6),
          fontSize: 16,
        ),
        border: InputBorder.none,
        prefixIcon: Icon(
          LineIcons.search,
          color: theme.colorScheme.primary.withOpacity(0.7),
        ),
      ),
      onChanged: _onSearchChanged,
      textInputAction: TextInputAction.search,
    );
  }

  PreferredSizeWidget _buildFilterBar(ThemeData theme) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(120),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(
            bottom: BorderSide(
              color: theme.colorScheme.outline.withOpacity(0.2),
              width: 1,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Filters',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _clearAllFilters,
                  child: Text(
                    'Clear All',
                    style: TextStyle(
                      color: theme.colorScheme.error,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildFilterChip(
                    theme,
                    icon: Icons.calendar_today,
                    label: _fromDate != null && _toDate != null
                        ? '${_fromDate!.day}/${_fromDate!.month} - ${_toDate!.day}/${_toDate!.month}'
                        : 'Date Range',
                    isActive: _fromDate != null && _toDate != null,
                    onTap: _selectDateRange,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildFilterChip(
                    theme,
                    icon: Icons.label,
                    label: _selectedTags.isNotEmpty
                        ? '${_selectedTags.length} Tags'
                        : 'Tags',
                    isActive: _selectedTags.isNotEmpty,
                    onTap: () => _showTagSelector(theme),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? theme.colorScheme.primary.withOpacity(0.1)
              : theme.colorScheme.surface,
          border: Border.all(
            color: isActive
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withOpacity(0.3),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withOpacity(0.6),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isActive
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withOpacity(0.7),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTagSelector(ThemeData theme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _TagSelectorBottomSheet(
        availableTags: _availableTags,
        selectedTags: _selectedTags,
        onTagsChanged: (tags) {
          setState(() {
            _selectedTags = tags;
          });
          _performSearch();
        },
        theme: theme,
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (!_isSearching) {
      return _buildSearchSuggestions(theme);
    }

    if (_isLoadingResults) {
      return _buildLoadingResults(theme);
    }

    if (_searchResults.isEmpty) {
      return _buildNoResults(theme);
    }

    return _buildSearchResults(theme);
  }

  Widget _buildSearchSuggestions(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Search Tips',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          _buildSearchTip(
            theme,
            icon: LineIcons.search,
            title: 'Search in titles, content, and tags',
            description: 'Type any word or phrase to find matching notes',
          ),
          _buildSearchTip(
            theme,
            icon: Icons.calendar_today,
            title: 'Filter by date range',
            description: 'Use filters to narrow down results by creation date',
          ),
          _buildSearchTip(
            theme,
            icon: LineIcons.tag,
            title: 'Filter by tags',
            description: 'Select specific tags to find related notes',
          ),
          const Spacer(),
          Center(
            child: Icon(
              LineIcons.search,
              size: 64,
              color: theme.colorScheme.primary.withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchTip(
    ThemeData theme, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: theme.colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingResults(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Searching...',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LineIcons.search,
            size: 64,
            color: theme.colorScheme.primary.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No notes found',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search terms or filters',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _clearAllFilters,
            icon: const Icon(Icons.clear_all),
            label: const Text('Clear All Filters'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color: theme.colorScheme.outline.withOpacity(0.1),
              ),
            ),
          ),
          child: Row(
            children: [
              Text(
                '${_searchResults.length} result${_searchResults.length == 1 ? '' : 's'}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
              const Spacer(),
              if (_fromDate != null ||
                  _toDate != null ||
                  _selectedTags.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Filtered',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _searchResults.length,
            itemBuilder: (context, index) {
              final result = _searchResults[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                child: _buildSearchResultCard(theme, result),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResultCard(ThemeData theme, NoteSearchResult result) {
    return GestureDetector(
      onTap: () => _openNote(result.note),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          result.note.noteTitle,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${result.relevanceScore.toStringAsFixed(1)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getContentPreview(result.note.noteContent),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(result.note.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                      if (result.note.tags.isNotEmpty) ...[
                        const SizedBox(width: 16),
                        Icon(
                          Icons.label,
                          size: 14,
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${result.note.tags.length} tags',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (result.note.tags.isNotEmpty)
              Container(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: result.note.tags.take(3).map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getContentPreview(String content) {
    final plainText =
        AdvancedNoteSearchService.extractPlainTextFromQuill(content);
    if (plainText.length <= 150) return plainText;
    return '${plainText.substring(0, 150)}...';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _openNote(NoteTakingModel note) {
    Navigator.push(
      context,
      PageTransition(
        child: CreateNote(note: note),
        type: PageTransitionType.rightToLeft,
        duration: const Duration(milliseconds: 300),
      ),
    );
  }
}

class _TagSelectorBottomSheet extends StatefulWidget {
  final List<String> availableTags;
  final List<String> selectedTags;
  final Function(List<String>) onTagsChanged;
  final ThemeData theme;

  const _TagSelectorBottomSheet({
    required this.availableTags,
    required this.selectedTags,
    required this.onTagsChanged,
    required this.theme,
  });

  @override
  State<_TagSelectorBottomSheet> createState() =>
      _TagSelectorBottomSheetState();
}

class _TagSelectorBottomSheetState extends State<_TagSelectorBottomSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200), // Reduced duration
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2), // Reduced slide distance
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    // Start animation immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleTag(String tag) {
    final newSelectedTags = List<String>.from(widget.selectedTags);
    if (newSelectedTags.contains(tag)) {
      newSelectedTags.remove(tag);
    } else {
      newSelectedTags.add(tag);
    }
    widget.onTagsChanged(newSelectedTags);
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          decoration: BoxDecoration(
            color: widget.theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              Flexible(
                child: _buildTagGrid(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Text(
            'Select Tags',
            style: widget.theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: widget.theme.colorScheme.primary,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.close,
              color: widget.theme.colorScheme.primary,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = (constraints.maxWidth / 120).floor().clamp(2, 4);

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 3.5,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: widget.availableTags.length,
          itemBuilder: (context, index) {
            final tag = widget.availableTags[index];
            final isSelected = widget.selectedTags.contains(tag);

            return _buildTagChip(tag, isSelected);
          },
        );
      },
    );
  }

  Widget _buildTagChip(String tag, bool isSelected) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _toggleTag(tag),
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? widget.theme.colorScheme.primary.withOpacity(0.2)
                : widget.theme.colorScheme.surface,
            border: Border.all(
              color: isSelected
                  ? widget.theme.colorScheme.primary
                  : widget.theme.colorScheme.outline.withOpacity(0.3),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  size: 16,
                  color: widget.theme.colorScheme.primary,
                ),
              if (isSelected) const SizedBox(width: 6),
              Expanded(
                child: Text(
                  tag,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isSelected
                        ? widget.theme.colorScheme.primary
                        : widget.theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomDateRangePicker extends StatefulWidget {
  final DateTime? fromDate;
  final DateTime? toDate;
  final ThemeData theme;
  final Function(DateTimeRange) onDateRangeSelected;

  const _CustomDateRangePicker({
    required this.fromDate,
    required this.toDate,
    required this.theme,
    required this.onDateRangeSelected,
  });

  @override
  State<_CustomDateRangePicker> createState() => _CustomDateRangePickerState();
}

class _CustomDateRangePickerState extends State<_CustomDateRangePicker>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  DateTime? _selectedFromDate;
  DateTime? _selectedToDate;
  DateTime _currentMonth = DateTime.now();
  bool _isSelectingEndDate = false;

  @override
  void initState() {
    super.initState();
    _selectedFromDate = widget.fromDate;
    _selectedToDate = widget.toDate;

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 250), // Reduced duration
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2), // Reduced slide distance
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    // Start animation after frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _selectDate(DateTime date) {
    if (_selectedFromDate == null || _isSelectingEndDate) {
      // Selecting end date
      if (_selectedFromDate != null && date.isBefore(_selectedFromDate!)) {
        // If end date is before start date, swap them
        setState(() {
          _selectedFromDate = date;
          _selectedToDate = _selectedFromDate;
        });
      } else {
        setState(() {
          _selectedToDate = date;
        });
      }
      _isSelectingEndDate = false;
    } else {
      // Selecting start date
      setState(() {
        _selectedFromDate = date;
        _isSelectingEndDate = true;
      });
    }
  }

  void _confirmSelection() {
    if (_selectedFromDate != null && _selectedToDate != null) {
      widget.onDateRangeSelected(
        DateTimeRange(start: _selectedFromDate!, end: _selectedToDate!),
      );
      Navigator.pop(context);
    }
  }

  void _clearSelection() {
    setState(() {
      _selectedFromDate = null;
      _selectedToDate = null;
      _isSelectingEndDate = false;
    });
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
  }

  bool _isDateInRange(DateTime date) {
    if (_selectedFromDate == null || _selectedToDate == null) return false;
    return date.isAfter(_selectedFromDate!.subtract(const Duration(days: 1))) &&
        date.isBefore(_selectedToDate!.add(const Duration(days: 1)));
  }

  bool _isDateSelected(DateTime date) {
    if (_selectedFromDate == null && _selectedToDate == null) return false;
    if (_selectedFromDate != null && _isSameDay(date, _selectedFromDate!))
      return true;
    if (_selectedToDate != null && _isSameDay(date, _selectedToDate!))
      return true;
    return false;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: widget.theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildHeader(),
              _buildDateRangeDisplay(),
              _buildCalendarHeader(),
              Expanded(child: _buildCalendar()),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: widget.theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.close,
              color: widget.theme.colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'Select Date Range',
            style: widget.theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: widget.theme.colorScheme.primary,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: _clearSelection,
            icon: Icon(
              Icons.clear_all,
              color: widget.theme.colorScheme.primary.withOpacity(0.7),
              size: 20,
            ),
            tooltip: 'Clear selection',
          ),
        ],
      ),
    );
  }

  Widget _buildDateRangeDisplay() {
    final fromText = _selectedFromDate != null
        ? '${_selectedFromDate!.day}/${_selectedFromDate!.month}/${_selectedFromDate!.year}'
        : 'Start Date';
    final toText = _selectedToDate != null
        ? '${_selectedToDate!.day}/${_selectedToDate!.month}/${_selectedToDate!.year}'
        : 'End Date';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildDateChip(
              label: 'From',
              date: fromText,
              isSelected: _selectedFromDate != null,
              isActive: !_isSelectingEndDate,
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            child: Icon(
              Icons.arrow_forward,
              color: widget.theme.colorScheme.primary.withOpacity(0.5),
              size: 20,
            ),
          ),
          Expanded(
            child: _buildDateChip(
              label: 'To',
              date: toText,
              isSelected: _selectedToDate != null,
              isActive: _isSelectingEndDate,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateChip({
    required String label,
    required String date,
    required bool isSelected,
    required bool isActive,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSelected
            ? widget.theme.colorScheme.primary.withOpacity(0.1)
            : widget.theme.colorScheme.surface,
        border: Border.all(
          color: isActive
              ? widget.theme.colorScheme.primary
              : isSelected
                  ? widget.theme.colorScheme.primary.withOpacity(0.3)
                  : widget.theme.colorScheme.outline.withOpacity(0.2),
          width: isActive ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: widget.theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            date,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected
                  ? widget.theme.colorScheme.primary
                  : widget.theme.colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          IconButton(
            onPressed: _previousMonth,
            icon: Icon(
              Icons.chevron_left,
              color: widget.theme.colorScheme.primary,
            ),
          ),
          Expanded(
            child: Text(
              '${_getMonthName(_currentMonth.month)} ${_currentMonth.year}',
              style: widget.theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: widget.theme.colorScheme.primary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            onPressed: _nextMonth,
            icon: Icon(
              Icons.chevron_right,
              color: widget.theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    final daysInMonth =
        DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    final firstDayOfMonth =
        DateTime(_currentMonth.year, _currentMonth.month, 1);
    final firstWeekday = firstDayOfMonth.weekday;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Days of week header
          Row(
            children: ['S', 'M', 'T', 'W', 'T', 'F', 'S'].map((day) {
              return Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    day,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: widget.theme.colorScheme.primary.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }).toList(),
          ),
          // Calendar grid
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1,
              ),
              itemCount: 42, // 6 weeks * 7 days
              itemBuilder: (context, index) {
                final dayOffset = index - (firstWeekday - 1);
                final day = dayOffset + 1;

                if (day < 1 || day > daysInMonth) {
                  return Container(); // Empty space
                }

                final date =
                    DateTime(_currentMonth.year, _currentMonth.month, day);
                final isInRange = _isDateInRange(date);
                final isSelected = _isDateSelected(date);
                final isToday = _isSameDay(date, DateTime.now());

                return GestureDetector(
                  onTap: () => _selectDate(date),
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? widget.theme.colorScheme.primary
                          : isInRange
                              ? widget.theme.colorScheme.primary
                                  .withOpacity(0.1)
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: isToday
                          ? Border.all(
                              color: widget.theme.colorScheme.primary,
                              width: 2,
                            )
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        day.toString(),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: isSelected || isToday
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: isSelected
                              ? widget.theme.colorScheme.onPrimary
                              : isInRange
                                  ? widget.theme.colorScheme.primary
                                  : widget.theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(
                  color: widget.theme.colorScheme.outline.withOpacity(0.3),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: widget.theme.colorScheme.onSurface.withOpacity(0.7),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: (_selectedFromDate != null && _selectedToDate != null)
                  ? _confirmSelection
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.theme.colorScheme.primary,
                foregroundColor: widget.theme.colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Text(
                'Confirm',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: widget.theme.colorScheme.onPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month - 1];
  }
}
