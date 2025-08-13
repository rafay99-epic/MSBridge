import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:line_icons/line_icons.dart';
import 'package:page_transition/page_transition.dart';
import 'package:msbridge/core/database/note_taking/note_taking.dart';
import 'package:msbridge/core/repo/hive_note_taking_repo.dart';
import 'package:msbridge/features/notes_taking/create/create_note.dart';
import 'package:msbridge/widgets/appbar.dart';

class TagFolderPage extends StatelessWidget {
  final String? tag;
  const TagFolderPage({super.key, this.tag});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final title = tag ?? 'Untagged';

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: CustomAppBar(title: title, showBackButton: true),
      body: FutureBuilder<ValueListenable<Box<NoteTakingModel>>>(
        future: HiveNoteTakingRepo.getNotesListenable(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      LineIcons.stickyNote,
                      size: 48,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading notes...',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.primary.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            );
          }

          return ValueListenableBuilder<Box<NoteTakingModel>>(
            valueListenable: snap.data!,
            builder: (context, box, _) {
              final all = box.values.toList();
              final filtered = tag == null
                  ? all.where((n) => n.tags.isEmpty).toList()
                  : all.where((n) => n.tags.contains(tag)).toList();

              if (filtered.isEmpty) {
                return _buildEmptyState(context, colorScheme, theme, title);
              }

              return CustomScrollView(
                slivers: [
                  // Header Section
                  SliverToBoxAdapter(
                    child: _buildHeaderSection(
                        context, colorScheme, theme, title, filtered.length),
                  ),

                  // Notes Grid
                  SliverPadding(
                    padding: const EdgeInsets.all(20),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.85,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final note = filtered[index];
                          return _buildNoteCard(
                            context,
                            note,
                            colorScheme,
                            theme,
                          );
                        },
                        childCount: filtered.length,
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
          );
        },
      ),
    );
  }

  Widget _buildHeaderSection(BuildContext context, ColorScheme colorScheme,
      ThemeData theme, String title, int noteCount) {
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
          color: colorScheme.primary.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              tag == null ? LineIcons.folderOpen : LineIcons.folder,
              size: 32,
              color: colorScheme.primary,
            ),
          ),

          const SizedBox(height: 16),

          // Title
          Text(
            title,
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

  Widget _buildEmptyState(BuildContext context, ColorScheme colorScheme,
      ThemeData theme, String title) {
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

  Widget _buildNoteCard(
    BuildContext context,
    NoteTakingModel note,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
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
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: colorScheme.outline.withOpacity(0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withOpacity(0.05),
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
              // Note Icon and Title
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      LineIcons.stickyNote,
                      size: 16,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      note.noteTitle.isEmpty ? '(Untitled)' : note.noteTitle,
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

              // Note Preview
              Expanded(
                child: Text(
                  _preview(note.noteContent),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.primary.withOpacity(0.7),
                    height: 1.4,
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              const SizedBox(height: 16),

              // Tags
              if (note.tags.isNotEmpty) ...[
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: note.tags
                      .take(2)
                      .map((tag) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: colorScheme.secondary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              tag,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.secondary,
                                fontSize: 10,
                              ),
                            ),
                          ))
                      .toList(),
                ),
                if (note.tags.length > 2) ...[
                  const SizedBox(height: 4),
                  Text(
                    '+${note.tags.length - 2} more',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.primary.withOpacity(0.5),
                      fontSize: 10,
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
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
    } catch (_) {
      return null;
    }
  }
}
