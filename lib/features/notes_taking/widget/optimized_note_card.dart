// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:intl/intl.dart';
import 'package:line_icons/line_icons.dart';

// Project imports:
import 'package:msbridge/core/database/note_taking/note_taking.dart';
import 'package:msbridge/features/notes_taking/read/read_note_page.dart';
import 'package:msbridge/features/notes_taking/version_history/version_history_screen.dart';
import 'package:msbridge/features/notes_taking/widget/optimized_build_content.dart';

class OptimizedNoteCard extends StatefulWidget {
  const OptimizedNoteCard({
    super.key,
    required this.note,
    required this.isSelected,
    required this.isSelectionMode,
    this.isGridLayout = false,
  });

  final NoteTakingModel note;
  final bool isSelected;
  final bool isSelectionMode;
  final bool isGridLayout;

  @override
  State<OptimizedNoteCard> createState() => _OptimizedNoteCardState();
}

class _OptimizedNoteCardState extends State<OptimizedNoteCard> {
  String? _formattedDate;
  String? _title;
  List<String>? _displayTags;

  @override
  void initState() {
    super.initState();
    _initializeCachedValues();
  }

  @override
  void didUpdateWidget(OptimizedNoteCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.note.updatedAt != widget.note.updatedAt ||
        oldWidget.note.noteTitle != widget.note.noteTitle ||
        oldWidget.note.tags != widget.note.tags) {
      _initializeCachedValues();
    }
  }

  void _initializeCachedValues() {
    final lastUpdated = DateTime.parse(widget.note.updatedAt.toString());
    _formattedDate = DateFormat('dd/MM/yyyy').format(lastUpdated);
    _title = widget.note.noteTitle.isEmpty ? 'Untitled' : widget.note.noteTitle;
    _displayTags = widget.note.tags.take(3).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Ensure cached values are initialized
    if (_formattedDate == null || _title == null || _displayTags == null) {
      _initializeCachedValues();
    }

    return RepaintBoundary(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: widget.isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.08)
              : theme.cardColor,
          border: widget.isSelected
              ? Border.all(color: theme.colorScheme.primary, width: 2)
              : Border.all(
                  color:
                      theme.colorScheme.outlineVariant.withValues(alpha: 0.25),
                ),
          boxShadow: widget.isSelected
              ? [
                  BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 8)
                ]
              : [],
        ),
        child: Card(
          elevation: widget.isSelected ? 6 : 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: theme.cardColor,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 6,
                          height: 28,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _title ?? 'Untitled',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: theme.colorScheme.primary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formattedDate ?? '',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.secondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => _showVersionHistory(context),
                          splashRadius: 20,
                          icon: Icon(
                            LineIcons.history,
                            size: 18,
                            color: theme.colorScheme.secondary,
                          ),
                          tooltip: 'History',
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          onPressed: () => _openRead(context),
                          splashRadius: 20,
                          icon: Icon(
                            LineIcons.eye,
                            size: 18,
                            color: theme.colorScheme.secondary,
                          ),
                          tooltip: 'Read',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: theme.colorScheme.outlineVariant
                          .withValues(alpha: 0.15),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Content - using optimized content builder
                OptimizedBuildContent(
                  key: ValueKey(
                      'content_${widget.note.noteId ?? widget.note.hashCode}'),
                  content: widget.note.noteContent,
                  theme: theme,
                ),

                const SizedBox(height: 12),

                // Tags
                if (_displayTags != null && _displayTags!.isNotEmpty) ...[
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final tag in _displayTags!)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            tag,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],

                Divider(
                  height: 1,
                  thickness: 1,
                  color:
                      theme.colorScheme.outlineVariant.withValues(alpha: 0.12),
                ),

                const SizedBox(height: 12),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 1),
                    if (widget.isSelectionMode)
                      Icon(Icons.check_circle, color: theme.colorScheme.primary)
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showVersionHistory(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VersionHistoryScreen(note: widget.note),
      ),
    );
  }

  void _openRead(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReadNotePage(note: widget.note),
      ),
    );
  }
}
