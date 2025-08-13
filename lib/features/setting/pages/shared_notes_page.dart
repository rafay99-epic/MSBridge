import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:msbridge/core/database/note_taking/note_taking.dart';
import 'package:msbridge/core/repo/hive_note_taking_repo.dart';
import 'package:msbridge/core/repo/share_repo.dart';
import 'package:msbridge/widgets/appbar.dart';
import 'package:msbridge/widgets/snakbar.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';

class SharedNotesPage extends StatefulWidget {
  const SharedNotesPage({super.key});

  @override
  State<SharedNotesPage> createState() => _SharedNotesPageState();
}

class _SharedNotesPageState extends State<SharedNotesPage> {
  Future<List<SharedNoteMeta>> _loadSharedNotes() async {
    return await ShareRepository.getSharedNotes();
  }

  Future<NoteTakingModel?> _getNote(String noteId) async {
    final notes = await HiveNoteTakingRepo.getNotes();
    try {
      return notes.firstWhere((n) => n.noteId == noteId);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: const CustomAppBar(title: 'Shared Notes', showBackButton: true),
      body: FutureBuilder<List<SharedNoteMeta>>(
        future: _loadSharedNotes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final shared = snapshot.data ?? [];
          if (shared.isEmpty) {
            return Center(
              child: Text(
                'No shared notes yet',
                style: TextStyle(color: theme.colorScheme.primary.withOpacity(0.7)),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemCount: shared.length,
            itemBuilder: (context, index) {
              final item = shared[index];
              return FutureBuilder<NoteTakingModel?>(
                future: _getNote(item.noteId),
                builder: (context, noteSnap) {
                  final note = noteSnap.data;
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: theme.colorScheme.secondary, width: 2),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      title: Text(
                        note?.noteTitle.isNotEmpty == true ? note!.noteTitle : (item.title.isNotEmpty ? item.title : 'Untitled'),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      subtitle: Text(
                        item.shareUrl,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: theme.colorScheme.primary.withOpacity(0.6)),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Copy link',
                            icon: Icon(LineIcons.copy, color: theme.colorScheme.primary),
                            onPressed: () async {
                              await Clipboard.setData(ClipboardData(text: item.shareUrl));
                              if (mounted) CustomSnackBar.show(context, 'Link copied');
                            },
                          ),
                          IconButton(
                            tooltip: 'Share',
                            icon: Icon(LineIcons.share, color: theme.colorScheme.secondary),
                            onPressed: () => Share.share(item.shareUrl),
                          ),
                          IconButton(
                            tooltip: 'Disable sharing',
                            icon: Icon(LineIcons.eyeSlash, color: Colors.redAccent),
                            onPressed: () async {
                              final n = note ?? (await _getNote(item.noteId));
                              if (n == null) return;
                              await ShareRepository.disableShare(n);
                              if (mounted) {
                                CustomSnackBar.show(context, 'Sharing disabled');
                                setState(() {});
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
