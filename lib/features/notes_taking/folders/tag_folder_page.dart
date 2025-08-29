import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bugfender/flutter_bugfender.dart';
import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:msbridge/core/database/note_taking/note_taking.dart';
import 'package:msbridge/core/repo/hive_note_taking_repo.dart';
import 'package:msbridge/widgets/appbar.dart';
import 'package:msbridge/features/notes_taking/folders/utils/date_filter.dart';
import 'package:msbridge/features/notes_taking/folders/widgets/folder_widgets.dart';

class TagFolderPage extends StatefulWidget {
  final String? tag;
  const TagFolderPage({super.key, this.tag});

  @override
  State<TagFolderPage> createState() => _TagFolderPageState();
}

class _TagFolderPageState extends State<TagFolderPage> {
  DateFilterSelection _selection = DateFilterSelection();
  final ScrollController _scrollController = ScrollController();
  static const int _pageSize = 20;
  int _currentPage = 0;
  List<NoteTakingModel> _filteredNotes = [];
  bool _isLoading = false;
  bool _hasMoreData = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreData();
    }
  }

  void _loadMoreData() {
    if (!_isLoading && _hasMoreData) {
      setState(() => _isLoading = true);
      Future.microtask(() {
        if (mounted) {
          setState(() {
            _currentPage++;
            _isLoading = false;
          });
        }
      });
    }
  }

  void _refreshData() {
    setState(() {
      _currentPage = 0;
      _filteredNotes = [];
      _hasMoreData = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final title = widget.tag ?? 'Untagged';

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: CustomAppBar(
        title: title,
        showBackButton: true,
        actions: [
          IconButton(
            tooltip: 'Filter by date',
            icon: const Icon(Icons.filter_list),
            onPressed: () async {
              final updated = await showDateFilterSheet(context, _selection);
              if (updated != null && mounted) {
                setState(() {
                  _selection = updated;
                  _refreshData();
                });
              }
            },
          ),
        ],
      ),
      body: FutureBuilder<ValueListenable<Box<NoteTakingModel>>>(
        future: HiveNoteTakingRepo.getNotesListenable(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  colorScheme.primary,
                ),
              ),
            );
          }

          return ValueListenableBuilder<Box<NoteTakingModel>>(
            valueListenable: snap.data!,
            builder: (context, box, _) {
              return _buildNotesList(box, colorScheme, theme, title);
            },
          );
        },
      ),
    );
  }

  Widget _buildNotesList(Box<NoteTakingModel> box, ColorScheme colorScheme,
      ThemeData theme, String title) {
    // Cache filtered notes to avoid recalculation
    if (_filteredNotes.isEmpty) {
      final all = box.values.toList();
      final byTag = widget.tag == null
          ? all.where((n) => n.tags.isEmpty).toList()
          : all.where((n) => n.tags.contains(widget.tag)).toList();
      _filteredNotes = applyDateFilter(byTag, _selection);
      _hasMoreData = _filteredNotes.length > _pageSize;
    }

    final visibleNotes =
        _filteredNotes.take((_currentPage + 1) * _pageSize).toList();

    if (visibleNotes.isEmpty) {
      return buildEmptyState(context, colorScheme, theme, title);
    }

    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverToBoxAdapter(
          child: buildFolderHeader(
            context,
            colorScheme,
            theme,
            title,
            _filteredNotes.length,
            showFolderOpen: widget.tag == null,
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.85,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index >= visibleNotes.length) {
                  return null;
                }
                return buildNoteCard(
                  context,
                  visibleNotes[index],
                  colorScheme,
                  theme,
                  _preview,
                );
              },
              childCount: visibleNotes.length,
            ),
          ),
        ),
        if (_hasMoreData && visibleNotes.length < _filteredNotes.length)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation<Color>(colorScheme.primary),
                ),
              ),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
      ],
    );
  }

  String _preview(String content) {
    try {
      final dynamic json = _tryJson(content);
      if (json is List) {
        return json
            .map((op) => op is Map && op['insert'] is String
                ? op['insert'] as String
                : '')
            .join(' ')
            .trim();
      }
      if (json is Map && json['ops'] is List) {
        final List ops = json['ops'];
        return ops
            .map((op) => op is Map && op['insert'] is String
                ? op['insert'] as String
                : '')
            .join(' ')
            .trim();
      }
    } catch (_) {}
    return content.replaceAll('\n', ' ').trim();
  }

  dynamic _tryJson(String s) {
    try {
      return jsonDecode(s);
    } catch (e) {
      FlutterBugfender.error('Error parsing JSON: $e');
      return null;
    }
  }
}
