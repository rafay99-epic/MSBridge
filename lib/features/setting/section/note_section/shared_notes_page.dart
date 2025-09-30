// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Package imports:
import 'package:flutter_bugfender/flutter_bugfender.dart';
import 'package:line_icons/line_icons.dart';
import 'package:share_plus/share_plus.dart';

// Project imports:
import 'package:msbridge/core/database/note_taking/note_taking.dart';
import 'package:msbridge/core/repo/hive_note_taking_repo.dart';
import 'package:msbridge/core/repo/share_repo.dart';
import 'package:msbridge/widgets/appbar.dart';
import 'package:msbridge/widgets/snakbar.dart';

class SharedNotesPage extends StatefulWidget {
  const SharedNotesPage({super.key});

  @override
  State<SharedNotesPage> createState() => _SharedNotesPageState();
}

class _SharedNotesPageState extends State<SharedNotesPage> {
  final Set<String> _disableInProgressNoteIds = <String>{};

  Future<List<SharedNoteMeta>> _loadSharedNotes() async {
    return await DynamicLink.getSharedNotes();
  }

  Future<void> _disableSharing(String noteId, NoteTakingModel? note) async {
    final n = note ?? (await _getNote(noteId));
    if (n == null) return;
    await DynamicLink.disableShare(n);
    if (mounted) {
      CustomSnackBar.show(context, 'Sharing disabled');
      setState(() {});
    }
  }

  Future<NoteTakingModel?> _getNote(String noteId) async {
    final notes = await HiveNoteTakingRepo.getNotes();
    try {
      return notes.firstWhere((n) => n.noteId == noteId);
    } catch (e) {
      FlutterBugfender.sendCrash(
          'Failed to get note: $noteId', StackTrace.current.toString());
      FlutterBugfender.error('Failed to get note: $noteId');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: const CustomAppBar(title: 'Shared Notes', showBackButton: true),
      body: FutureBuilder<List<SharedNoteMeta>>(
        future: _loadSharedNotes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      LineIcons.share,
                      size: 48,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading shared notes...',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.primary.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            );
          }

          final shared = snapshot.data ?? [];
          if (shared.isEmpty) {
            return _buildEmptyState(context, colorScheme, theme);
          }

          return CustomScrollView(
            slivers: [
              // Header Section
              SliverToBoxAdapter(
                child: _buildHeaderSection(
                    context, colorScheme, theme, shared.length),
              ),

              // Shared Notes List
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = shared[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: FutureBuilder<NoteTakingModel?>(
                          future: _getNote(item.noteId),
                          builder: (context, noteSnap) {
                            final note = noteSnap.data;
                            return _buildSharedNoteCard(
                              context,
                              item,
                              note,
                              colorScheme,
                              theme,
                            );
                          },
                        ),
                      );
                    },
                    childCount: shared.length,
                  ),
                ),
              ),

              // Bottom spacing
              const SliverToBoxAdapter(
                child: SizedBox(height: 20),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeaderSection(BuildContext context, ColorScheme colorScheme,
      ThemeData theme, int noteCount) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary.withValues(alpha: 0.05),
            colorScheme.secondary.withValues(alpha: 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              LineIcons.share,
              size: 32,
              color: colorScheme.primary,
            ),
          ),

          const SizedBox(height: 16),

          // Title
          Text(
            "Shared Notes",
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.primary,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          // Note Count
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '$noteCount ${noteCount == 1 ? 'note' : 'notes'} shared',
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

  Widget _buildEmptyState(
      BuildContext context, ColorScheme colorScheme, ThemeData theme) {
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
              LineIcons.share,
              size: 64,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No shared notes yet',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Share your notes with others to collaborate and stay connected.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.primary.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSharedNoteCard(
    BuildContext context,
    SharedNoteMeta item,
    NoteTakingModel? note,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Note Title and Actions Row
            Row(
              children: [
                // Note Icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    LineIcons.stickyNote,
                    size: 16,
                    color: colorScheme.primary,
                  ),
                ),

                const SizedBox(width: 12),

                // Note Title
                Expanded(
                  child: Text(
                    note?.noteTitle.isNotEmpty == true
                        ? note!.noteTitle
                        : (item.title.isNotEmpty ? item.title : 'Untitled'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.primary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Share URL
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    LineIcons.link,
                    size: 16,
                    color: colorScheme.primary.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.shareUrl,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.primary.withValues(alpha: 0.7),
                        fontFamily: 'monospace',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  context,
                  'Copy Link',
                  LineIcons.copy,
                  colorScheme.primary,
                  () async {
                    await Clipboard.setData(ClipboardData(text: item.shareUrl));
                    if (context.mounted) {
                      CustomSnackBar.show(context, 'Link copied to clipboard',
                          isSuccess: true);
                    }
                  },
                ),
                _buildActionButton(
                  context,
                  'Share',
                  LineIcons.share,
                  colorScheme.secondary,
                  () => SharePlus.instance.share(item.shareUrl as ShareParams),
                ),
                _buildActionButton(
                  context,
                  _disableInProgressNoteIds.contains(item.noteId)
                      ? 'Disabling...'
                      : 'Disable',
                  _disableInProgressNoteIds.contains(item.noteId)
                      ? Icons.hourglass_empty
                      : LineIcons.eyeSlash,
                  _disableInProgressNoteIds.contains(item.noteId)
                      ? Colors.grey
                      : Colors.redAccent,
                  () async {
                    if (_disableInProgressNoteIds.contains(item.noteId)) return;

                    if (mounted) {
                      setState(() {
                        _disableInProgressNoteIds.add(item.noteId);
                      });
                    }

                    try {
                      await _disableSharing(item.noteId, note);
                    } catch (e) {
                      FlutterBugfender.sendCrash(
                          'Failed to disable sharing: $e',
                          StackTrace.current.toString());
                      FlutterBugfender.error('Failed to disable sharing: $e');
                      if (context.mounted) {
                        CustomSnackBar.show(
                            context, 'Failed to disable sharing: $e');
                      }
                    } finally {
                      if (mounted) {
                        setState(() {
                          _disableInProgressNoteIds.remove(item.noteId);
                        });
                      }
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 16),
          label: Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: color.withValues(alpha: 0.1),
            foregroundColor: color,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}
