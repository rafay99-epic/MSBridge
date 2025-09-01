import 'package:flutter/material.dart';
import 'package:flutter_bugfender/flutter_bugfender.dart';
import 'package:line_icons/line_icons.dart';
import 'package:msbridge/core/database/note_reading/notes_model.dart';
import 'package:msbridge/core/database/note_taking/note_taking.dart';
import 'package:msbridge/core/services/advance_search/advanced_note_search_service.dart';
import 'package:msbridge/features/msnotes/notes_detail.dart';
import 'package:msbridge/features/notes_taking/create/create_note.dart';
import 'package:msbridge/features/notes_taking/search/date_ranger.dart';
import 'package:msbridge/features/notes_taking/search/tag_selector.dart';
import 'package:page_transition/page_transition.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';

class UnifiedSearchResult {
  final dynamic note; // Can be NoteTakingModel or MSNote
  final double relevanceScore;
  final bool isReadingNote; // Flag to identify the type

  UnifiedSearchResult({
    required this.note,
    required this.relevanceScore,
    required this.isReadingNote,
  });
}

class AdvancedSearchScreen extends StatefulWidget {
  final List<NoteTakingModel> takingNotes;
  final List<MSNote> readingNotes;
  final bool searchReadingNotes; // Flag to determine which notes to search

  const AdvancedSearchScreen({
    super.key,
    required this.takingNotes,
    this.readingNotes = const [],
    this.searchReadingNotes = false,
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
  List<UnifiedSearchResult> _searchResults = [];
  List<String> searchSuggestions = [];
  bool _isSearching = false;
  bool _showFilters = false;
  bool _isLoadingResults = false;

  // Filter states
  DateTime? _fromDate;
  DateTime? _toDate;
  List<String> _selectedTags = [];
  bool includeDeleted = false;

  // Available tags from all notes
  List<String> _availableTags = const [];

  // Flag to track if tag extraction is complete
  bool _tagsExtractionComplete = false;

  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 250),
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
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    // Start animation immediately to reduce perceived lag
    _animationController.forward();

    // Request focus after animation starts
    _searchFocusNode.requestFocus();

    // Extract tags in the background after UI is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _extractAvailableTags();
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
    // Start with an empty list to avoid null checks
    setState(() {
      _availableTags = [];
    });

    // Only extract tags from taking notes as reading notes don't have tags
    try {
      // Prepare data for background processing
      final simpleNotes = widget.takingNotes
          .map((note) => {
                'tags': note.tags,
              })
          .toList();

      // Use compute for background processing
      compute(_extractTagsInBackground, simpleNotes).then((tags) {
        if (mounted) {
          setState(() {
            _availableTags = tags;
            _tagsExtractionComplete = true;
          });
        }
      }).catchError((error) {
        FlutterBugfender.sendCrash(
            'Error extracting tags: $error', StackTrace.current.toString());
        FlutterBugfender.error('Error extracting tags: $error');
        // Fallback to main thread
        _extractTagsInMainThread();
      });
    } catch (e) {
      FlutterBugfender.sendCrash(
          'Error extracting tags: $e', StackTrace.current.toString());
      FlutterBugfender.error('Error extracting tags: $e');
      // Fallback to main thread
      _extractTagsInMainThread();
    }
  }

  void _extractTagsInMainThread() {
    final Set<String> tags = {};
    for (final note in widget.takingNotes) {
      if (note.tags.isNotEmpty) {
        tags.addAll(note.tags);
      }
    }
    if (mounted) {
      setState(() {
        _availableTags = tags.toList()..sort();
        _tagsExtractionComplete = true;
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
    // Cancel previous timer to avoid multiple searches
    _debounceTimer?.cancel();

    setState(() {
      _searchQuery = query;
      _isSearching = query.isNotEmpty;

      // Clear results immediately when query is empty
      if (query.isEmpty) {
        _searchResults = [];
        searchSuggestions = [];
      }
    });

    if (query.isEmpty) return;

    // Use a shorter debounce time for better responsiveness
    _debounceTimer = Timer(const Duration(milliseconds: 200), () {
      if (mounted) {
        // Get search suggestions based on the active note type
        if (widget.searchReadingNotes) {
          // For reading notes, we might need a different approach for suggestions
          searchSuggestions = _getReadingNotesSuggestions(query);
        } else {
          // For taking notes, use the existing service
          searchSuggestions = AdvancedNoteSearchService.getSearchSuggestions(
            widget.takingNotes,
            query,
          );
        }

        // Process search in background
        _performSearchInBackground();
      }
    });
  }

  List<String> _getReadingNotesSuggestions(String query) {
    // Simple implementation for reading notes suggestions
    final Set<String> suggestions = {};

    for (final note in widget.readingNotes) {
      if (note.lectureTitle.toLowerCase().contains(query.toLowerCase())) {
        suggestions.add(note.lectureTitle);
      }
      if (note.subject.toLowerCase().contains(query.toLowerCase())) {
        suggestions.add(note.subject);
      }
      if (note.lectureDescription.toLowerCase().contains(query.toLowerCase())) {
        suggestions.add(note.lectureDescription.substring(
            0,
            note.lectureDescription.length > 30
                ? 30
                : note.lectureDescription.length));
      }
    }

    return suggestions.take(5).toList();
  }

  void _performSearchInBackground() {
    try {
      // Show loading indicator
      setState(() {
        _isLoadingResults = true;
      });

      if (widget.searchReadingNotes) {
        // Search in reading notes
        _searchInReadingNotes();
      } else {
        // Search in taking notes
        _searchInTakingNotes();
      }
    } catch (e) {
      FlutterBugfender.sendCrash(
          'Error performing search: $e', StackTrace.current.toString());
      FlutterBugfender.error('Error performing search: $e');
      // Handle errors
      setState(() {
        _searchResults = [];
        _isLoadingResults = false;
      });
    }
  }

  void _searchInReadingNotes() {
    // Prepare minimal data for search
    widget.readingNotes
        .map((note) => {
              'id': note.id,
              'lectureTitle': note.lectureTitle,
              'lectureDescription': note.lectureDescription,
              'pubDate': note.pubDate,
              'subject': note.subject,
              'body': note.body ?? '',
            })
        .toList();
    Future.microtask(_searchInReadingNotesMainThread);
  }

  void _searchInReadingNotesMainThread() {
    try {
      final results = <UnifiedSearchResult>[];
      final query = _searchQuery.toLowerCase();

      for (final note in widget.readingNotes) {
        double score = 0;

        // Check title match (highest weight)
        if (note.lectureTitle.toLowerCase().contains(query)) {
          score += 3.0;
        }

        // Check subject match
        if (note.subject.toLowerCase().contains(query)) {
          score += 2.0;
        }

        // Check description match
        if (note.lectureDescription.toLowerCase().contains(query)) {
          score += 1.5;
        }

        // Check body match
        if (note.body != null && note.body!.toLowerCase().contains(query)) {
          score += 1.0;
        }

        // Date filtering
        if (_fromDate != null && _toDate != null) {
          try {
            final noteDate = DateTime.parse(note.pubDate);
            if (noteDate.isBefore(_fromDate!) || noteDate.isAfter(_toDate!)) {
              continue; // Skip this note if outside date range
            }
          } catch (e) {
            FlutterBugfender.sendCrash(
                'Error parsing date: $e', StackTrace.current.toString());
            FlutterBugfender.error('Error parsing date: $e');
            // If date parsing fails, include the note anyway
            continue;
          }
        }

        // Add to results if there's any match
        if (score > 0) {
          results.add(UnifiedSearchResult(
            note: note,
            relevanceScore: score,
            isReadingNote: true,
          ));
        }
      }

      // Sort by relevance score
      results.sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));

      if (mounted) {
        setState(() {
          _searchResults = results;
          _isLoadingResults = false;
        });
      }
    } catch (e) {
      FlutterBugfender.sendCrash('Error searching in reading notes: $e',
          StackTrace.current.toString());
      FlutterBugfender.error('Error searching in reading notes: $e');
      if (mounted) {
        setState(() {
          _searchResults = [];
          _isLoadingResults = false;
        });
      }
    }
  }

  void _searchInTakingNotes() {
    widget.takingNotes
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
    // Temporarily avoid compute: return to main-thread implementation
    Future.microtask(_searchInTakingNotesMainThread);
  }

  void _searchInTakingNotesMainThread() {
    try {
      final noteResults = AdvancedNoteSearchService.searchNotes(
        notes: widget.takingNotes,
        query: _searchQuery,
        fromDate: _fromDate,
        toDate: _toDate,
        tags: _selectedTags.isNotEmpty ? _selectedTags : null,
        includeDeleted: includeDeleted,
      );

      // Convert to unified results
      final unifiedResults = noteResults
          .map((result) => UnifiedSearchResult(
                note: result.note,
                relevanceScore: result.relevanceScore,
                isReadingNote: false,
              ))
          .toList();

      if (mounted) {
        setState(() {
          _searchResults = unifiedResults;
          _isLoadingResults = false;
        });
      }
    } catch (e) {
      FlutterBugfender.sendCrash(
          'Error searching in taking notes: $e', StackTrace.current.toString());
      FlutterBugfender.error('Error searching in taking notes: $e');
      if (mounted) {
        setState(() {
          _searchResults = [];
          _isLoadingResults = false;
        });
      }
    }
  }

  void _performSearch() {
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
      builder: (context) => CustomDateRangePicker(
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
        hintText: widget.searchReadingNotes
            ? 'Search lectures, subjects, or content...'
            : 'Search notes, tags, or content...',
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
                // Only show tags filter for taking notes
                if (!widget.searchReadingNotes)
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
    // Don't show if tags aren't loaded yet
    if (!_tagsExtractionComplete) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => TagSelectorBottomSheet(
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
    // Use ListView instead of Column for better performance
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          widget.searchReadingNotes ? 'Search Lectures' : 'Search Notes',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 16),
        _buildSearchTip(
          theme,
          icon: LineIcons.search,
          title: widget.searchReadingNotes
              ? 'Search in titles, subjects, and content'
              : 'Search in titles, content, and tags',
          description: 'Type any word or phrase to find matching items',
        ),
        _buildSearchTip(
          theme,
          icon: Icons.calendar_today,
          title: 'Filter by date range',
          description: widget.searchReadingNotes
              ? 'Narrow down results by publication date'
              : 'Narrow down results by creation date',
        ),
        if (!widget.searchReadingNotes)
          _buildSearchTip(
            theme,
            icon: LineIcons.tag,
            title: 'Filter by tags',
            description: 'Select specific tags to find related notes',
          ),
        const SizedBox(height: 60),
        Center(
          child: Icon(
            LineIcons.search,
            size: 64,
            color: theme.colorScheme.primary.withOpacity(0.3),
          ),
        ),
      ],
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
            widget.searchReadingNotes ? 'No lectures found' : 'No notes found',
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
          // Use ListView.builder with cacheExtent for better performance
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _searchResults.length,
            cacheExtent: 500, // Cache more items
            itemBuilder: (context, index) {
              final result = _searchResults[index];
              return _buildSearchResultItem(theme, result, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResultItem(
      ThemeData theme, UnifiedSearchResult result, int index) {
    // Use RepaintBoundary to optimize rendering
    return RepaintBoundary(
      child: Container(
        margin: EdgeInsets.only(bottom: 16),
        child: result.isReadingNote
            ? _buildReadingNoteCard(theme, result)
            : _buildTakingNoteCard(theme, result),
      ),
    );
  }

  Widget _buildReadingNoteCard(ThemeData theme, UnifiedSearchResult result) {
    final note = result.note as MSNote;

    // Format date
    String formattedDate = 'No date';
    try {
      final date = DateTime.parse(note.pubDate);
      formattedDate = _formatDate(date);
    } catch (e) {
      FlutterBugfender.sendCrash(
          'Error parsing date: $e', StackTrace.current.toString());
      FlutterBugfender.error('Error parsing date: $e');
      formattedDate = 'No date';
    }

    return GestureDetector(
      onTap: () => _openReadingNote(note),
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
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          note.lectureTitle,
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
                          result.relevanceScore.toStringAsFixed(1),
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
                    note.lectureDescription,
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
                        formattedDate,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.book,
                        size: 14,
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        note.subject,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTakingNoteCard(ThemeData theme, UnifiedSearchResult result) {
    final note = result.note as NoteTakingModel;

    // Pre-compute content preview for better performance
    final contentPreview = _getContentPreview(note.noteContent);
    final formattedDate = _formatDate(note.createdAt);

    return GestureDetector(
      onTap: () => _openTakingNote(note),
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
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          note.noteTitle,
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
                          result.relevanceScore.toStringAsFixed(1),
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
                    contentPreview,
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
                        formattedDate,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                      if (note.tags.isNotEmpty) ...[
                        const SizedBox(width: 16),
                        Icon(
                          Icons.label,
                          size: 14,
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${note.tags.length} tags',
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
            if (note.tags.isNotEmpty) _buildTagsList(theme, note.tags),
          ],
        ),
      ),
    );
  }

  Widget _buildTagsList(ThemeData theme, List<String> tags) {
    // Limit number of tags shown for performance
    final displayTags = tags.length > 3 ? tags.sublist(0, 3) : tags;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: displayTags.map((tag) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
    );
  }

  String _getContentPreview(String content) {
    // Cache this result if possible
    final plainText =
        AdvancedNoteSearchService.extractPlainTextFromQuill(content);
    if (plainText.length <= 150) return plainText;
    return '${plainText.substring(0, 150)}...';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'No date';

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

  void _openTakingNote(NoteTakingModel note) {
    Navigator.push(
      context,
      PageTransition(
        child: CreateNote(note: note),
        type: PageTransitionType.rightToLeft,
        duration: const Duration(milliseconds: 250),
      ),
    );
  }

  void _openReadingNote(MSNote note) {
    Navigator.push(
      context,
      PageTransition(
        child: LectureDetailScreen(lecture: note),
        type: PageTransitionType.rightToLeft,
        duration: const Duration(milliseconds: 250),
      ),
    );
  }
}
