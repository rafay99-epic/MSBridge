import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:msbridge/core/database/note_taking/note_taking.dart';
import 'package:msbridge/core/repo/hive_note_taking_repo.dart';
import 'package:msbridge/widgets/appbar.dart';
import 'package:msbridge/features/notes_taking/folders/utils/date_filter.dart';
import 'package:msbridge/features/notes_taking/folders/widgets/folder_widgets.dart';

class TagFolderPage extends StatefulWidget {
  final String? tag;
  const TagFolderPage({super.key, this.tag});

  @override
  State<TagFolderPage> createState() => _TagFolderPageState();
}

class _TagFolderPageState extends State<TagFolderPage> {
  DateFilterSelection _selection = DateFilterSelection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final title = widget.tag ?? 'Untagged';

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: CustomAppBar(
        title: title,
        showBackButton: true,
        actions: [
          IconButton(
            tooltip: 'Filter by date',
            icon: const Icon(Icons.filter_list),
            onPressed: () async {
              final updated = await showDateFilterSheet(context, _selection);
              if (updated != null && mounted) {
                setState(() => _selection = updated);
              }
            },
          ),
        ],
      ),
      body: FutureBuilder<ValueListenable<Box<NoteTakingModel>>>(
        future: HiveNoteTakingRepo.getNotesListenable(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  colorScheme.primary,
                ),
              ),
            );
          }

          return ValueListenableBuilder<Box<NoteTakingModel>>(
            valueListenable: snap.data!,
            builder: (context, box, _) {
              final all = box.values.toList();
              final byTag = widget.tag == null
                  ? all.where((n) => n.tags.isEmpty).toList()
                  : all.where((n) => n.tags.contains(widget.tag)).toList();
              final filtered = applyDateFilter(byTag, _selection);

              if (filtered.isEmpty) {
                return buildEmptyState(context, colorScheme, theme, title);
              }

              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: buildFolderHeader(
                      context,
                      colorScheme,
                      theme,
                      title,
                      filtered.length,
                      showFolderOpen: widget.tag == null,
                    ),
                  ),
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
                        (context, index) => buildNoteCard(
                          context,
                          filtered[index],
                          colorScheme,
                          theme,
                          _preview,
                        ),
                        childCount: filtered.length,
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 20)),
                ],
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
