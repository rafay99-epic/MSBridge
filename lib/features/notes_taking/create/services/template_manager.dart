// Dart imports:
import 'dart:convert';

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_bugfender/flutter_bugfender.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:line_icons/line_icons.dart';

// Project imports:
import 'package:msbridge/core/database/templates/note_template.dart';
import 'package:msbridge/core/repo/template_repo.dart';
import 'package:msbridge/features/templates/templates_hub.dart';
import 'package:msbridge/widgets/snakbar.dart';

class TemplateManager {
  static Future<void> openTemplatesPicker(
    BuildContext context,
    Function(NoteTemplate) onTemplateSelected,
  ) async {
    final theme = Theme.of(context);
    final listenable = await TemplateRepo.getTemplatesListenable();
    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return RepaintBoundary(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.outline.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Title
                  Text(
                    'Select Template',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Templates list
                  Flexible(
                    child: SizedBox(
                      height: MediaQuery.of(ctx).size.height * 0.5,
                      child: ValueListenableBuilder<Box<NoteTemplate>>(
                        valueListenable: listenable,
                        builder: (context, Box<NoteTemplate> box, _) {
                          final items = box.values.toList();
                          if (items.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    LineIcons.fileAlt,
                                    size: 48,
                                    color: theme.colorScheme.primary
                                        .withValues(alpha: 0.3),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No templates yet',
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.7),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Create your first template to get started',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.5),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          // Sort only once when items change
                          items.sort(
                              (a, b) => b.updatedAt.compareTo(a.updatedAt));

                          return ListView.builder(
                            itemCount: items.length,
                            itemBuilder: (context, index) {
                              final template = items[index];
                              return RepaintBoundary(
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 6.0),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(12),
                                      onTap: () async {
                                        Navigator.pop(context);
                                        onTemplateSelected(template);
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.surface
                                              .withValues(alpha: 0.3),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color: theme.colorScheme.outline
                                                .withValues(alpha: 0.1),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 48,
                                              height: 48,
                                              decoration: BoxDecoration(
                                                color: theme.colorScheme.primary
                                                    .withValues(alpha: 0.1),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Icon(
                                                LineIcons.fileAlt,
                                                size: 24,
                                                color:
                                                    theme.colorScheme.primary,
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    template.title,
                                                    style: theme
                                                        .textTheme.titleMedium
                                                        ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: theme.colorScheme
                                                          .onSurface,
                                                    ),
                                                  ),
                                                  if (template
                                                      .tags.isNotEmpty) ...[
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      template.tags.join(' · '),
                                                      style: theme
                                                          .textTheme.bodySmall
                                                          ?.copyWith(
                                                        color: theme.colorScheme
                                                            .onSurface
                                                            .withValues(
                                                                alpha: 0.7),
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                  Icons.open_in_new,
                                                  size: 20),
                                              onPressed: () async {
                                                Navigator.pop(context);
                                                await Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        const TemplatesHubPage(),
                                                  ),
                                                );
                                              },
                                              tooltip: 'Manage templates',
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static Future<void> applyTemplateInEditor(
    NoteTemplate template,
    QuillController controller,
    TextEditingController titleController,
    ValueNotifier<List<String>> tagsNotifier,
    Function(Document) reinitializeController,
    BuildContext context,
  ) async {
    try {
      final templateDoc = Document.fromJson(jsonDecode(template.contentJson));
      // If editor empty, replace; else confirm replace vs insert
      final isEmpty = controller.document.isEmpty();
      if (isEmpty) {
        reinitializeController(templateDoc);
        titleController.text = template.title;
        tagsNotifier.value = List<String>.from(template.tags);
      } else {
        final action = await showDialog<String>(
          context: context,
          builder: (dctx) {
            final theme = Theme.of(dctx);
            return AlertDialog(
              backgroundColor: theme.colorScheme.surface,
              title: Text('Apply template?',
                  style: TextStyle(color: theme.colorScheme.primary)),
              content: Text('Replace current content or insert at cursor?',
                  style: TextStyle(color: theme.colorScheme.primary)),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(dctx, 'insert'),
                    child: const Text('Insert')),
                TextButton(
                    onPressed: () => Navigator.pop(dctx, 'replace'),
                    child: const Text('Replace')),
                TextButton(
                    onPressed: () => Navigator.pop(dctx, 'cancel'),
                    child: const Text('Cancel')),
              ],
            );
          },
        );
        if (action == 'replace') {
          reinitializeController(templateDoc);
          titleController.text = template.title;
          tagsNotifier.value = List<String>.from(template.tags);
        } else if (action == 'insert') {
          final templateDelta = templateDoc.toDelta();
          final currentSelection = controller.selection;
          if (currentSelection.isValid) {
            for (final op in templateDelta.toList()) {
              controller.document
                  .insert(currentSelection.baseOffset, op.data.toString());
            }
            final insertedLen = templateDelta.length;
            controller.updateSelection(
              TextSelection.collapsed(
                offset: currentSelection.baseOffset + insertedLen,
              ),
              ChangeSource.local,
            );
          }
        }
      }
      if (context.mounted) CustomSnackBar.show(context, 'Template applied');
    } catch (e) {
      FlutterBugfender.sendCrash(
          'Failed to apply template: $e', StackTrace.current.toString());
      FlutterBugfender.error('Failed to apply template: $e');
      if (context.mounted) {
        CustomSnackBar.show(context, 'Failed to apply template',
            isSuccess: false);
      }
    }
  }
}
