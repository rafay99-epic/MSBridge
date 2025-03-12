import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:msbridge/core/database/note_taking/note_taking.dart';
import 'package:msbridge/core/provider/pin_note_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_quill/flutter_quill.dart';

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
  Widget _buildContent(String content, ThemeData theme) {
    try {
      final jsonResult = jsonDecode(content);
      if (jsonResult is List) {
        final document = Document.fromJson(jsonResult);
        return AbsorbPointer(
          child: QuillEditor.basic(
            configurations: QuillEditorConfigurations(
              controller: QuillController(
                document: document,
                selection: const TextSelection.collapsed(offset: 0),
              ),
              sharedConfigurations: const QuillSharedConfigurations(),
            ),
          ),
        );
      } else {
        return Text(
          content,
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      return Text(
        content,
        maxLines: 4,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.primary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final noteProvider = Provider.of<NoteePinProvider>(context, listen: false);

    final isPinned = noteProvider.isNotePinned(widget.note.noteId.toString());

    return AnimatedContainer(
      duration: const Duration(seconds: 3),
      curve: Curves.bounceIn,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: widget.isSelected
            ? theme.colorScheme.secondary.withOpacity(0.1)
            : null,
        border: widget.isSelected
            ? Border.all(color: theme.colorScheme.secondary, width: 2)
            : null,
      ),
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: widget.isSelected
            ? theme.colorScheme.secondary.withOpacity(0.1)
            : null,
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
              _buildContent(widget.note.noteContent, theme),
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
                  if (widget.isSelectionMode)
                    Checkbox(
                      value: widget.isSelected,
                      onChanged: (value) {
                        (context as Element).markNeedsBuild();
                      },
                      activeColor: theme.colorScheme.primary,
                    )
                  else
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
                          isPinned
                              ? LineIcons.thumbtack
                              : Icons.push_pin_outlined,
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
      ),
    );
  }
}
