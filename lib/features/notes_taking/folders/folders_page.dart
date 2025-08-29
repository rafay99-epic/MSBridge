import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:line_icons/line_icons.dart';
import 'package:page_transition/page_transition.dart';
import 'package:msbridge/core/database/note_taking/note_taking.dart';
import 'package:msbridge/core/repo/hive_note_taking_repo.dart';
import 'package:msbridge/features/notes_taking/folders/tag_folder_page.dart';
import 'package:msbridge/widgets/appbar.dart';

class FoldersPage extends StatefulWidget {
  const FoldersPage({super.key});

  @override
  State<FoldersPage> createState() => _FoldersPageState();
}

class _FoldersPageState extends State<FoldersPage> {
  ValueListenable<Box<NoteTakingModel>>? _notesListenable;

  // Cache for computed values to avoid recalculation
  Map<String, int>? _cachedTagCounts;
  int? _cachedUntagged;
  List<String>? _cachedSortedTags;
  List<NoteTakingModel>? _lastProcessedNotes;

  @override
  void initState() {
    super.initState();
    _initializeListenable();
  }

  Future<void> _initializeListenable() async {
    _notesListenable = await HiveNoteTakingRepo.getNotesListenable();
    if (mounted) setState(() {});
  }

  // Memoized computation - only recalculates when notes actually change
  void _computeTagData(List<NoteTakingModel> notes) {
    if (_lastProcessedNotes != null &&
        listEquals(_lastProcessedNotes!, notes)) {
      return; // No change, use cached values
    }

    final Map<String, int> tagCounts = {};
    int untagged = 0;

    for (final note in notes) {
      if (note.tags.isEmpty) {
        untagged++;
      } else {
        for (final tag in note.tags) {
          tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
        }
      }
    }

    _cachedTagCounts = tagCounts;
    _cachedUntagged = untagged;
    _cachedSortedTags = tagCounts.keys.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    _lastProcessedNotes = List.from(notes);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: const CustomAppBar(title: 'Folders', showBackButton: true),
      body: _notesListenable == null
          ? _buildLoadingState(colorScheme, theme)
          : ValueListenableBuilder<Box<NoteTakingModel>>(
              valueListenable: _notesListenable!,
              builder: (context, box, _) {
                final notes = box.values.toList();
                _computeTagData(notes);

                return CustomScrollView(
                  slivers: [
                    // Use const header when possible
                    SliverToBoxAdapter(
                      child: _HeaderSection(
                          colorScheme: colorScheme, theme: theme),
                    ),

                    // Optimized grid
                    SliverPadding(
                      padding: const EdgeInsets.all(20),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.9,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _buildFolderItem(
                              context, index, colorScheme, theme),
                          childCount: (_cachedUntagged! > 0 ? 1 : 0) +
                              _cachedSortedTags!.length,
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(
                      child: SizedBox(height: 20),
                    ),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildLoadingState(ColorScheme colorScheme, ThemeData theme) {
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
              LineIcons.folder,
              size: 48,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading folders...',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.primary.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFolderItem(BuildContext context, int index,
      ColorScheme colorScheme, ThemeData theme) {
    final bool hasUntagged = _cachedUntagged! > 0;

    if (index == 0 && hasUntagged) {
      return _FolderCard(
        title: 'Untagged',
        count: _cachedUntagged!,
        icon: LineIcons.folderOpen,
        colorScheme: colorScheme,
        theme: theme,
        tag: null,
      );
    }

    final tagIndex = hasUntagged ? index - 1 : index;
    if (tagIndex < _cachedSortedTags!.length) {
      final tag = _cachedSortedTags![tagIndex];
      return _FolderCard(
        title: tag,
        count: _cachedTagCounts![tag]!,
        icon: LineIcons.folder,
        colorScheme: colorScheme,
        theme: theme,
        tag: tag,
      );
    }

    return const SizedBox.shrink();
  }
}

// Separate stateless widgets for better performance
class _HeaderSection extends StatelessWidget {
  const _HeaderSection({
    required this.colorScheme,
    required this.theme,
  });

  final ColorScheme colorScheme;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.primary.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: colorScheme.primary.withOpacity(0.4),
                width: 1.5,
              ),
            ),
            child: Icon(
              LineIcons.folder,
              size: 32,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Organize Your Notes",
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.primary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            "Browse your notes by tags and categories. Each folder contains related notes for easy access.",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.primary.withOpacity(0.7),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _FolderCard extends StatelessWidget {
  const _FolderCard({
    required this.title,
    required this.count,
    required this.icon,
    required this.colorScheme,
    required this.theme,
    required this.tag,
  });

  final String title;
  final int count;
  final IconData icon;
  final ColorScheme colorScheme;
  final ThemeData theme;
  final String? tag;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            PageTransition(
              child: TagFolderPage(tag: tag),
              type: PageTransitionType.rightToLeft,
              duration: const Duration(milliseconds: 300),
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: colorScheme.primary.withOpacity(0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withOpacity(0.15),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.primary.withOpacity(0.4),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    icon,
                    size: 24,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.primary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: colorScheme.primary.withOpacity(0.4),
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    '$count ${count == 1 ? 'note' : 'notes'}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
