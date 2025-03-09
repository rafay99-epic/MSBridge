import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:msbridge/backend/hive/note_taking/note_taking.dart';
import 'package:msbridge/backend/provider/pin_note_provider.dart';
import 'package:provider/provider.dart';

class NoteCard extends StatefulWidget {
  const NoteCard({
    super.key,
    required this.note,
  });

  final NoteTakingModel note;

  @override
  State<NoteCard> createState() => _NoteCardState();
}

class _NoteCardState extends State<NoteCard> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final noteProvider = Provider.of<NoteProvider>(context, listen: false);

    final isPinned = noteProvider.isNotePinned(widget.note.noteId.toString());

    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.note.noteTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              widget.note.noteContent,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${DateTime.parse(widget.note.updatedAt.toString()).day}/${DateTime.parse(widget.note.updatedAt.toString()).month}/${DateTime.parse(widget.note.updatedAt.toString()).year}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder:
                      (Widget child, Animation<double> animation) {
                    return ScaleTransition(scale: animation, child: child);
                  },
                  child: IconButton(
                    key: ValueKey<bool>(isPinned),
                    hoverColor: theme.colorScheme.secondary,
                    icon: Icon(
                      isPinned ? LineIcons.mapPin : LineIcons.mapPin,
                    ),
                    color: theme.colorScheme.primary,
                    onPressed: () {
                      noteProvider.togglePin(widget.note.noteId.toString());
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
