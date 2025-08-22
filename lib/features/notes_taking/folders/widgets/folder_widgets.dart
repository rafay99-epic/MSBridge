import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:msbridge/core/database/note_taking/note_taking.dart';
import 'package:msbridge/features/notes_taking/create/create_note.dart';
import 'package:page_transition/page_transition.dart';
import 'package:intl/intl.dart';

Widget buildFolderHeader(BuildContext context, ColorScheme colorScheme,
    ThemeData theme, String title, int noteCount,
    {bool showFolderOpen = false}) {
  return Container(
    margin: const EdgeInsets.all(20),
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          colorScheme.primary.withOpacity(0.05),
          colorScheme.secondary.withOpacity(0.02),
        ],
      ),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: colorScheme.outline.withOpacity(0.35),
        width: 1.8,
      ),
    ),
    child: Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.1),
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
            color: colorScheme.primary.withOpacity(0.1),
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
            color: colorScheme.primary.withOpacity(0.1),
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
            color: colorScheme.primary.withOpacity(0.7),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}

Widget buildNoteCard(
  BuildContext context,
  NoteTakingModel note,
  ColorScheme colorScheme,
  ThemeData theme,
  String Function(String) preview,
) {
  final updatedLabel = DateFormat('dd MMM yyyy').format(note.updatedAt);
  return GestureDetector(
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
    child: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.surfaceContainerHighest,
            colorScheme.surfaceContainerHighest.withOpacity(0.96),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.35),
          width: 1.8,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.18),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: colorScheme.primary.withOpacity(0.35),
                      width: 1.2,
                    ),
                  ),
                  child: Icon(LineIcons.stickyNote,
                      color: colorScheme.primary, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    note.noteTitle.isEmpty ? '(Untitled)' : note.noteTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: colorScheme.primary,
                      letterSpacing: 0.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Expanded(
              child: Text(
                preview(note.noteContent),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.85),
                  height: 1.45,
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 14),
            if (note.tags.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: note.tags
                    .take(3)
                    .map((tag) => _chip(theme, colorScheme, tag))
                    .toList(),
              ),
              const SizedBox(height: 10),
            ],
            Row(
              children: [
                Icon(Icons.schedule, size: 14, color: colorScheme.outline),
                const SizedBox(width: 6),
                Text(
                  updatedLabel,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.outline,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _chip(ThemeData theme, ColorScheme colorScheme, String text) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: colorScheme.secondary.withOpacity(0.16),
      borderRadius: BorderRadius.circular(12),
      border:
          Border.all(color: colorScheme.secondary.withOpacity(0.35), width: 1),
    ),
    child: Text(
      text,
      style: theme.textTheme.labelSmall?.copyWith(
        color: colorScheme.secondary,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}
