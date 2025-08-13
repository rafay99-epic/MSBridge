import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:line_icons/line_icons.dart';
import 'package:msbridge/core/database/note_taking/note_taking.dart';
import 'package:msbridge/core/provider/pin_note_provider.dart';
import 'package:msbridge/features/notes_taking/widget/build_content.dart';
import 'package:provider/provider.dart';

class NoteCard extends StatefulWidget {
  const NoteCard({
    super.key,
    required this.note,
    required this.isSelected,
    required this.isSelectionMode,
  });

  final NoteTakingModel note;
  final bool isSelected;
  final bool isSelectionMode;

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
      child: Stack(
        children: [
          // Left accent bar
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 5,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.35),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),
          ),
          Card(
            elevation: widget.isSelected ? 6 : 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: theme.cardColor,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                      const SizedBox(width: 32),
                    ],
                  ),
                  const SizedBox(height: 8),
                  buildContent(widget.note.noteContent, theme),
                  const SizedBox(height: 12),
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
                    const SizedBox(height: 10),
                  ],
                  // Gradient divider to indicate end/start boundary
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
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        formattedDate,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.colorScheme.secondary),
                      ),
                      if (widget.isSelectionMode)
                        Icon(Icons.check_circle,
                            color: theme.colorScheme.primary)
                    ],
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) =>
                  ScaleTransition(scale: animation, child: child),
              child: IconButton(
                key: ValueKey<bool>(isPinned),
                icon: Icon(
                    isPinned ? LineIcons.thumbtack : Icons.push_pin_outlined),
                color: theme.colorScheme.primary,
                onPressed: () =>
                    noteProvider.togglePin(widget.note.noteId.toString()),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
