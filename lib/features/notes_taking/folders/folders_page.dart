import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:line_icons/line_icons.dart';
import 'package:page_transition/page_transition.dart';
import 'package:msbridge/core/database/note_taking/note_taking.dart';
import 'package:msbridge/core/repo/hive_note_taking_repo.dart';
import 'package:msbridge/features/notes_taking/folders/tag_folder_page.dart';
import 'package:msbridge/widgets/appbar.dart';

class FoldersPage extends StatelessWidget {
  const FoldersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: const CustomAppBar(title: 'Folders', showBackButton: true),
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

          return ValueListenableBuilder<Box<NoteTakingModel>>(
            valueListenable: snap.data!,
            builder: (context, box, _) {
              final notes = box.values.toList();
              final Map<String, int> tagCounts = {};
              int untagged = 0;

              for (final n in notes) {
                if (n.tags.isEmpty) {
                  untagged++;
                } else {
                  for (final t in n.tags) {
                    tagCounts[t] = (tagCounts[t] ?? 0) + 1;
                  }
                }
              }

              final tags = tagCounts.keys.toList()
                ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

              return CustomScrollView(
                slivers: [
                  // Header Section
                  SliverToBoxAdapter(
                    child: _buildHeaderSection(context, colorScheme, theme),
                  ),

                  // Folders Grid
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
                        (context, index) {
                          if (index == 0 && untagged > 0) {
                            return _buildFolderCard(
                              context,
                              'Untagged',
                              untagged,
                              LineIcons.folderOpen,
                              colorScheme,
                              theme,
                              null,
                            );
                          }

                          final tagIndex = untagged > 0 ? index - 1 : index;
                          if (tagIndex < tags.length) {
                            final tag = tags[tagIndex];
                            return _buildFolderCard(
                              context,
                              tag,
                              tagCounts[tag]!,
                              LineIcons.folder,
                              colorScheme,
                              theme,
                              tag,
                            );
                          }

                          return null;
                        },
                        childCount: (untagged > 0 ? 1 : 0) + tags.length,
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

  Widget _buildHeaderSection(
      BuildContext context, ColorScheme colorScheme, ThemeData theme) {
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
          color: colorScheme.primary.withOpacity(0.3), // Prominent border
          width: 2, // Thicker border
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.2), // Enhanced shadow
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.15), // More prominent
              shape: BoxShape.circle,
              border: Border.all(
                // Add border to icon container
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

          // Title
          Text(
            "Organize Your Notes",
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.primary,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          // Subtitle
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

  Widget _buildFolderCard(
    BuildContext context,
    String title,
    int count,
    IconData icon,
    ColorScheme colorScheme,
    ThemeData theme,
    String? tag,
  ) {
    return GestureDetector(
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
      child: Container(
        decoration: BoxDecoration(
          color:
              colorScheme.surfaceContainerHighest, // Match search screen color
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: colorScheme.primary.withOpacity(0.3), // Prominent border
            width: 2, // Thicker border
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withOpacity(0.2), // Enhanced shadow
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Folder Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color:
                      colorScheme.primary.withOpacity(0.15), // More prominent
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    // Add border to icon container
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

              // Folder Name
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700, // Increased weight
                  color: colorScheme.primary,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 6),

              // Note Count
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color:
                      colorScheme.primary.withOpacity(0.15), // More prominent
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    // Add border to count container
                    color: colorScheme.primary.withOpacity(0.4),
                    width: 1.5,
                  ),
                ),
                child: Text(
                  '$count ${count == 1 ? 'note' : 'notes'}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600, // Increased weight
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
