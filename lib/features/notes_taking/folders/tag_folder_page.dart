import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:line_icons/line_icons.dart';
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
    final title = tag ?? 'Untagged';
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: CustomAppBar(title: title, showBackButton: true),
      body: FutureBuilder<ValueListenable<Box<NoteTakingModel>>>(
        future: HiveNoteTakingRepo.getNotesListenable(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          return ValueListenableBuilder<Box<NoteTakingModel>>(
            valueListenable: snap.data!,
            builder: (context, box, _) {
              final all = box.values.toList();
              final filtered = tag == null
                  ? all.where((n) => n.tags.isEmpty).toList()
                  : all.where((n) => n.tags.contains(tag)).toList();
              if (filtered.isEmpty) {
                return Center(
                  child: Text('No notes', style: TextStyle(color: theme.colorScheme.primary.withOpacity(0.7))),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(12),
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemCount: filtered.length,
                itemBuilder: (context, i) {
                  final n = filtered[i];
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: theme.colorScheme.secondary, width: 2),
                    ),
                    child: ListTile(
                      leading: Icon(LineIcons.stickyNote, color: theme.colorScheme.secondary),
                      title: Text(n.noteTitle.isEmpty ? '(Untitled)' : n.noteTitle, style: TextStyle(color: theme.colorScheme.primary)),
                      subtitle: Text(
                        _preview(n.noteContent),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: theme.colorScheme.primary.withOpacity(0.7)),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => CreateNote(note: n)),
                        );
                      },
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

  String _preview(String content) {
    try {
      final dynamic json = _tryJson(content);
      if (json is List) {
        return json.map((op) => op is Map && op['insert'] is String ? op['insert'] as String : '').join(' ').trim();
      }
      if (json is Map && json['ops'] is List) {
        final List ops = json['ops'];
        return ops.map((op) => op is Map && op['insert'] is String ? op['insert'] as String : '').join(' ').trim();
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
