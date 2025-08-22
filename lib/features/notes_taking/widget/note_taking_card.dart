import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:line_icons/line_icons.dart';
import 'package:msbridge/core/database/note_taking/note_taking.dart';
import 'package:msbridge/core/provider/pin_note_provider.dart';
import 'package:msbridge/features/notes_taking/widget/build_content.dart';
import 'package:msbridge/features/notes_taking/version_history/version_history_screen.dart';
import 'package:provider/provider.dart';

class NoteCard extends StatefulWidget {
  const NoteCard({
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
  State<NoteCard> createState() => _NoteCardState();
}

class _NoteCardState extends State<NoteCard> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final noteProvider = Provider.of<NoteePinProvider>(context, listen: false);
    final isPinned = noteProvider.isNotePinned(widget.note.noteId.toString());

    final lastUpdated = DateTime.parse(widget.note.updatedAt.toString());
    final formattedDate = DateFormat('dd/MM/yyyy').format(lastUpdated);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: widget.isSelected
            ? theme.colorScheme.primary.withOpacity(0.08)
            : theme.cardColor,
        border: widget.isSelected
            ? Border.all(color: theme.colorScheme.primary, width: 2)
            : Border.all(
                color: theme.colorScheme.outlineVariant.withOpacity(0.25),
              ),
        boxShadow: widget.isSelected
            ? [
                BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                    blurRadius: 8)
              ]
            : [],
      ),
      child: Card(
        elevation: widget.isSelected ? 6 : 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: theme.cardColor,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section with Title and Icons
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title - gets full width to breathe
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left accent bar indicator
                      Container(
                        width: 4,
                        height: 24,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.35),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Title - takes full width
                      Expanded(
                        child: Text(
                          widget.note.noteTitle,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Subtle separator line
                  Container(
                    height: 1,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.outlineVariant.withOpacity(0.2),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Action buttons with text labels
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Left side - Version History
                      TextButton.icon(
                        onPressed: () => _showVersionHistory(context),
                        style: TextButton.styleFrom(
                          minimumSize: const Size(0, 36),
                          backgroundColor: theme
                              .colorScheme.surfaceContainerHighest
                              .withOpacity(0.3),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: Icon(
                          LineIcons.history,
                          size: 18,
                          color: theme.colorScheme.secondary,
                        ),
                        label: Text(
                          'History',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                      ),

                      // Right side - Pin Button
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (child, animation) =>
                            ScaleTransition(scale: animation, child: child),
                        child: TextButton.icon(
                          key: ValueKey<bool>(isPinned),
                          onPressed: () => noteProvider
                              .togglePin(widget.note.noteId.toString()),
                          style: TextButton.styleFrom(
                            minimumSize: const Size(0, 36),
                            backgroundColor: isPinned
                                ? theme.colorScheme.primary.withOpacity(0.2)
                                : theme.colorScheme.surfaceContainerHighest
                                    .withOpacity(0.3),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: Icon(
                            isPinned
                                ? LineIcons.thumbtack
                                : Icons.push_pin_outlined,
                            size: 18,
                            color: isPinned
                                ? theme.colorScheme.primary
                                : theme.colorScheme.secondary,
                          ),
                          label: Text(
                            isPinned ? 'Pinned' : 'Pin',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: isPinned
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.secondary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Content Section
              buildContent(widget.note.noteContent, theme),

              const SizedBox(height: 12),

              // Tags Section
              if (widget.note.tags.isNotEmpty) ...[
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final tag in widget.note.tags.take(3))
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

              // Gradient divider
              Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.outlineVariant.withOpacity(0.0),
                      theme.colorScheme.outlineVariant.withOpacity(0.6),
                      theme.colorScheme.outlineVariant.withOpacity(0.0),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Footer Section with Date and Selection
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    formattedDate,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.secondary),
                  ),
                  if (widget.isSelectionMode)
                    Icon(Icons.check_circle, color: theme.colorScheme.primary)
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showVersionHistory(BuildContext context) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            VersionHistoryScreen(note: widget.note),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 200),
      ),
    );
  }
}
