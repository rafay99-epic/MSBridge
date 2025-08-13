import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:line_icons/line_icons.dart';
import 'package:msbridge/core/database/note_taking/note_taking.dart';
import 'package:msbridge/core/repo/hive_note_taking_repo.dart';
import 'package:msbridge/features/notes_taking/folders/tag_folder_page.dart';
import 'package:msbridge/widgets/appbar.dart';

class FoldersPage extends StatelessWidget {
  const FoldersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: const CustomAppBar(title: 'Folders', showBackButton: true),
      body: FutureBuilder<ValueListenable<Box<NoteTakingModel>>>(
        future: HiveNoteTakingRepo.getNotesListenable(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
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
              final tags = tagCounts.keys.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

              return ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  if (untagged > 0)
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: theme.colorScheme.secondary, width: 2),
                      ),
                      child: ListTile(
                        leading: Icon(LineIcons.folderOpen, color: theme.colorScheme.secondary),
                        title: const Text('Untagged'),
                        trailing: CircleAvatar(
                          radius: 12,
                          backgroundColor: theme.colorScheme.secondary,
                          child: Text('$untagged', style: TextStyle(color: theme.colorScheme.surface, fontSize: 12)),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const TagFolderPage(tag: null)),
                          );
                        },
                      ),
                    ),
                  for (final t in tags)
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: theme.colorScheme.secondary, width: 2),
                      ),
                      child: ListTile(
                        leading: Icon(LineIcons.folder, color: theme.colorScheme.secondary),
                        title: Text(t, style: TextStyle(color: theme.colorScheme.primary)),
                        trailing: CircleAvatar(
                          radius: 12,
                          backgroundColor: theme.colorScheme.secondary,
                          child: Text('${tagCounts[t]}', style: TextStyle(color: theme.colorScheme.surface, fontSize: 12)),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => TagFolderPage(tag: t)),
                          );
                        },
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
