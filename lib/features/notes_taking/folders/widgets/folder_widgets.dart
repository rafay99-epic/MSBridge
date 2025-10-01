// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:intl/intl.dart';
import 'package:line_icons/line_icons.dart';
import 'package:page_transition/page_transition.dart';

// Project imports:
import 'package:msbridge/core/database/note_taking/note_taking.dart';
import 'package:msbridge/features/notes_taking/create/create_note.dart';
import 'package:msbridge/features/notes_taking/read/read_note_page.dart';

Widget buildFolderHeader(BuildContext context, ColorScheme colorScheme,
    ThemeData theme, String title, int noteCount,
    {bool showFolderOpen = false}) {
  return Container(
    margin: const EdgeInsets.all(20),
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: colorScheme.primary.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: colorScheme.outline.withValues(alpha: 0.35),
        width: 1.8,
      ),
    ),
    child: Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            showFolderOpen ? LineIcons.folderOpen : LineIcons.folder,
            size: 32,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: colorScheme.primary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            '$noteCount ${noteCount == 1 ? 'note' : 'notes'}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

Widget buildEmptyState(
  BuildContext context,
  ColorScheme colorScheme,
  ThemeData theme,
  String title,
) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            LineIcons.stickyNote,
            size: 64,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'No notes found',
          style: theme.textTheme.headlineSmall?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'This folder is empty. Create some notes to get started!',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.primary.withValues(alpha: 0.7),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}

class OptimizedNoteCard extends StatelessWidget {
  final NoteTakingModel note;
  final ColorScheme colorScheme;
  final ThemeData theme;
  final String Function(String) preview;

  const OptimizedNoteCard({
    super.key,
    required this.note,
    required this.colorScheme,
    required this.theme,
    required this.preview,
  });

  @override
  Widget build(BuildContext context) {
    final updatedLabel = DateFormat('dd MMM yyyy').format(note.updatedAt);
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final cardHeight = isTablet ? 180.0 : 160.0;
    final iconSize = isTablet ? 20.0 : 18.0;
    final padding = isTablet ? 20.0 : 16.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            PageTransition(
              child: CreateNote(note: note),
              type: PageTransitionType.rightToLeft,
              duration: const Duration(milliseconds: 300),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: cardHeight,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: colorScheme.primary.withValues(alpha: 0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: isTablet ? 44 : 40,
                      height: isTablet ? 44 : 40,
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colorScheme.primary.withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(LineIcons.stickyNote,
                          color: colorScheme.primary, size: iconSize),
                    ),
                    SizedBox(width: isTablet ? 16 : 12),
                    Expanded(
                      child: Text(
                        note.noteTitle.isEmpty ? '(Untitled)' : note.noteTitle,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.primary,
                          fontSize: isTablet ? 16 : 15,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _buildReadButton(context, isTablet),
                  ],
                ),
                SizedBox(height: isTablet ? 16 : 12),
                Expanded(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: colorScheme.surface.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      preview(note.noteContent),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.8),
                        height: 1.4,
                        fontSize: isTablet ? 14 : 13,
                      ),
                      maxLines: isTablet ? 4 : 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                SizedBox(height: isTablet ? 12 : 8),
                if (note.tags.isNotEmpty) ...[
                  _buildTagsRow(note.tags, theme, colorScheme, isTablet),
                  SizedBox(height: isTablet ? 12 : 8),
                ],
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.schedule,
                          size: isTablet ? 16 : 14, color: colorScheme.primary),
                      SizedBox(width: isTablet ? 8 : 6),
                      Expanded(
                        child: Text(
                          updatedLabel,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.primary,
                            fontSize: isTablet ? 12 : 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReadButton(BuildContext context, bool isTablet) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            PageTransition(
              child: ReadNotePage(note: note),
              type: PageTransitionType.rightToLeft,
              duration: const Duration(milliseconds: 300),
            ),
          );
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: EdgeInsets.all(isTablet ? 12 : 10),
          decoration: BoxDecoration(
            color: colorScheme.secondary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: colorScheme.secondary.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Icon(
            LineIcons.eye,
            size: isTablet ? 18 : 16,
            color: colorScheme.secondary,
          ),
        ),
      ),
    );
  }

  Widget _buildTagsRow(List<String> tags, ThemeData theme,
      ColorScheme colorScheme, bool isTablet) {
    final displayTags = tags.take(2).toList();
    return Wrap(
      spacing: isTablet ? 8 : 6,
      runSpacing: isTablet ? 6 : 4,
      children: displayTags
          .map((tag) => _buildTagChip(theme, colorScheme, tag, isTablet))
          .toList(),
    );
  }

  Widget _buildTagChip(
      ThemeData theme, ColorScheme colorScheme, String text, bool isTablet) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 14 : 12, vertical: isTablet ? 8 : 6),
      decoration: BoxDecoration(
        color: colorScheme.secondary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: colorScheme.secondary.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Text(
        text,
        style: theme.textTheme.labelSmall?.copyWith(
          color: colorScheme.secondary,
          fontWeight: FontWeight.w600,
          fontSize: isTablet ? 12 : 11,
        ),
      ),
    );
  }
}

Widget buildNoteCard(
  BuildContext context,
  NoteTakingModel note,
  ColorScheme colorScheme,
  ThemeData theme,
  String Function(String) preview,
) {
  return OptimizedNoteCard(
    note: note,
    colorScheme: colorScheme,
    theme: theme,
    preview: preview,
  );
}
