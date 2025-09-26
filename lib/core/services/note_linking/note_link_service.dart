import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:msbridge/core/database/note_taking/note_taking.dart';
import 'package:msbridge/widgets/custom_snackbar.dart';

class NoteLinkService {
  static final NoteLinkService _instance = NoteLinkService._internal();
  factory NoteLinkService() => _instance;
  NoteLinkService._internal();

  /// Parse note content for [[title]] links and return list of note IDs
  static List<String> parseLinksFromContent(String content) {
    final linkPattern = RegExp(r'\[\[([^\]]+)\]\]');
    final matches = linkPattern.allMatches(content);

    return matches.map((match) {
      final linkText = match.group(1)?.trim() ?? '';

      // Handle direct note ID format: [[note:noteId]]
      if (linkText.startsWith('note:')) {
        return linkText.substring(5);
      }

      // Handle title-based links: [[Title]]
      return linkText;
    }).toList();
  }

  /// Resolve link text to note ID by searching for notes with matching title
  static Future<String?> resolveLinkToNoteId(String linkText,
      {String? excludeNoteId}) async {
    try {
      final notesBox = await Hive.openBox<NoteTakingModel>('notesBox');
      final notes = notesBox.values
          .where((note) => !note.isDeleted && note.noteId != excludeNoteId)
          .toList();

      // First try exact match
      for (final note in notes) {
        if (note.noteTitle.toLowerCase() == linkText.toLowerCase()) {
          return note.noteId;
        }
      }

      // Then try partial match
      for (final note in notes) {
        if (note.noteTitle.toLowerCase().contains(linkText.toLowerCase())) {
          return note.noteId;
        }
      }

      return null;
    } catch (e) {
      debugPrint('Error resolving link: $e');
      return null;
    }
  }

  /// Get all notes that link to a specific note (backlinks)
  static Future<List<NoteTakingModel>> getBacklinks(String noteId) async {
    try {
      final notesBox = await Hive.openBox<NoteTakingModel>('notesBox');
      final notes = notesBox.values
          .where((note) =>
              !note.isDeleted && note.outgoingLinkIds.contains(noteId))
          .toList();

      return notes;
    } catch (e) {
      debugPrint('Error getting backlinks: $e');
      return [];
    }
  }

  /// Update outgoing links for a note based on its content
  static Future<void> updateNoteLinks(NoteTakingModel note) async {
    try {
      final linkTexts = parseLinksFromContent(note.noteContent);
      final resolvedIds = <String>[];

      for (final linkText in linkTexts) {
        final noteId =
            await resolveLinkToNoteId(linkText, excludeNoteId: note.noteId);
        if (noteId != null && !resolvedIds.contains(noteId)) {
          resolvedIds.add(noteId);
        }
      }

      // Update the note with resolved link IDs
      final updatedNote = note.copyWith(
        outgoingLinkIds: resolvedIds,
        updatedAt: DateTime.now(),
        isSynced: false,
      );

      final notesBox = await Hive.openBox<NoteTakingModel>('notesBox');
      await notesBox.put(note.noteId, updatedNote);
    } catch (e) {
      debugPrint('Error updating note links: $e');
    }
  }

  /// Insert a link at cursor position in Quill editor
  static void insertLinkInEditor(
    BuildContext context,
    String noteId,
    String noteTitle,
    Function(String linkText) onInsert,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.outline.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Insert Link',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Theme.of(context)
                              .colorScheme
                              .outline
                              .withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.link,
                            color: Theme.of(context).colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              noteTitle,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: Theme.of(context)
                                    .colorScheme
                                    .outline
                                    .withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.8),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              onInsert('[[$noteTitle]]');
                              CustomSnackBar.show(
                                context,
                                'Link inserted',
                                SnackBarType.success,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Theme.of(context).colorScheme.primary,
                              foregroundColor:
                                  Theme.of(context).colorScheme.onPrimary,
                            ),
                            child: Text(
                              'Insert Link',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Show note picker for linking
  static Future<void> showNotePicker(
    BuildContext context,
    Function(String noteId, String noteTitle) onNoteSelected,
  ) async {
    try {
      final notesBox = await Hive.openBox<NoteTakingModel>('notesBox');
      final notes = notesBox.values.where((note) => !note.isDeleted).toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      if (notes.isEmpty) {
        CustomSnackBar.show(
          context,
          'No notes available to link',
          SnackBarType.error,
        );
        return;
      }

      showModalBottomSheet(
        context: context,
        backgroundColor: Theme.of(context).colorScheme.surface,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (ctx) {
          return SafeArea(
            child: SizedBox(
              height: MediaQuery.of(ctx).size.height * 0.7,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 4),
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .outline
                            .withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.link,
                          color: Theme.of(context).colorScheme.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Select Note to Link',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: notes.length,
                      itemBuilder: (context, index) {
                        final note = notes[index];
                        return ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.note,
                              color: Theme.of(context).colorScheme.primary,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            note.noteTitle,
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            'Updated ${_formatDate(note.updatedAt)}',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withOpacity(0.6),
                                    ),
                          ),
                          onTap: () {
                            Navigator.pop(ctx);
                            onNoteSelected(note.noteId!, note.noteTitle);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } catch (e) {
      CustomSnackBar.show(
        context,
        'Error loading notes: $e',
        SnackBarType.error,
      );
    }
  }

  static String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
