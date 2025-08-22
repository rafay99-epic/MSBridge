import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:line_icons/line_icons.dart';
import 'package:msbridge/core/database/templates/note_template.dart';
import 'package:msbridge/core/repo/template_repo.dart';
import 'package:msbridge/features/notes_taking/create/create_note.dart';
import 'package:msbridge/utils/uuid.dart';
import 'package:msbridge/widgets/snakbar.dart';
import 'package:page_transition/page_transition.dart';

class TemplatesHubPage extends StatefulWidget {
  const TemplatesHubPage({super.key});

  @override
  State<TemplatesHubPage> createState() => _TemplatesHubPageState();
}

class _TemplatesHubPageState extends State<TemplatesHubPage> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Templates'),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.primary,
        actions: [
          IconButton(
            icon: const Icon(LineIcons.plusCircle),
            onPressed: _createNewTemplate,
            tooltip: 'New Template',
          ),
        ],
      ),
      body: FutureBuilder<ValueListenable<Box<NoteTemplate>>>(
        future: TemplateRepo.getTemplatesListenable(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
              ),
            );
          }
          final listenable = snapshot.data!;
          return ValueListenableBuilder(
            valueListenable: listenable,
            builder: (context, Box<NoteTemplate> box, _) {
              final items = box.values
                  .where((t) =>
                      _search.isEmpty ||
                      t.title.toLowerCase().contains(_search.toLowerCase()))
                  .toList()
                ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Search templates...',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: (v) => setState(() => _search = v.trim()),
                    ),
                  ),
                  Expanded(
                    child: items.isEmpty
                        ? Center(
                            child: Text('No templates yet',
                                style: TextStyle(
                                    color: theme.colorScheme.primary)),
                          )
                        : ListView.separated(
                            itemCount: items.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final t = items[index];
                              return ListTile(
                                title: Text(t.title,
                                    style: TextStyle(
                                        color: theme.colorScheme.primary)),
                                subtitle: t.tags.isEmpty
                                    ? null
                                    : Text(t.tags.join(' · '),
                                        style: TextStyle(
                                            color: theme.colorScheme.primary
                                                .withOpacity(0.7))),
                                leading: const Icon(LineIcons.fileAlt),
                                trailing: PopupMenuButton<String>(
                                  onSelected: (val) {
                                    if (val == 'edit') _editTemplate(t);
                                    if (val == 'delete') _deleteTemplate(t);
                                  },
                                  itemBuilder: (ctx) => const [
                                    PopupMenuItem(
                                        value: 'edit', child: Text('Edit')),
                                    PopupMenuItem(
                                        value: 'delete', child: Text('Delete')),
                                  ],
                                ),
                                onTap: () => _applyTemplate(t),
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

  Future<void> _createNewTemplate() async {
    await Navigator.push(
      context,
      PageTransition(
        child: TemplateEditorPage(),
        type: PageTransitionType.rightToLeft,
        duration: const Duration(milliseconds: 300),
      ),
    );
  }

  Future<void> _editTemplate(NoteTemplate t) async {
    await Navigator.push(
      context,
      PageTransition(
        child: TemplateEditorPage(template: t),
        type: PageTransitionType.rightToLeft,
        duration: const Duration(milliseconds: 300),
      ),
    );
  }

  Future<void> _deleteTemplate(NoteTemplate t) async {
    await TemplateRepo.deleteTemplate(t);
    if (mounted) CustomSnackBar.show(context, 'Template deleted');
  }

  Future<void> _applyTemplate(NoteTemplate t) async {
    await Navigator.push(
      context,
      PageTransition(
        child: CreateNote(initialTemplate: t),
        type: PageTransitionType.rightToLeft,
        duration: const Duration(milliseconds: 300),
      ),
    );
    // If you want immediate create with auto-save, you can also route with
    // arguments; actual wiring will happen in editor picker integration.
  }
}

class TemplateEditorPage extends StatefulWidget {
  TemplateEditorPage({super.key, this.template});
  final NoteTemplate? template;

  @override
  State<TemplateEditorPage> createState() => _TemplateEditorPageState();
}

class _TemplateEditorPageState extends State<TemplateEditorPage> {
  late QuillController _controller;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _tagInputController = TextEditingController();
  final ValueNotifier<List<String>> _tagsNotifier =
      ValueNotifier<List<String>>(<String>[]);

  @override
  void initState() {
    super.initState();
    if (widget.template != null) {
      _titleController.text = widget.template!.title;
      try {
        _controller = QuillController(
          document: Document.fromJson(jsonDecode(widget.template!.contentJson)),
          selection: const TextSelection.collapsed(offset: 0),
        );
      } catch (_) {
        _controller = QuillController.basic();
      }
      _tagsNotifier.value = List<String>.from(widget.template!.tags);
    } else {
      _controller = QuillController.basic();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _titleController.dispose();
    _tagInputController.dispose();
    _tagsNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(widget.template == null ? 'New Template' : 'Edit Template'),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.primary,
        actions: [
          IconButton(
            icon: const Icon(LineIcons.save),
            onPressed: _saveTemplate,
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: 'Template title',
                border: InputBorder.none,
              ),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tagInputController,
                    decoration: const InputDecoration(
                      hintText: 'Add tag and press +',
                    ),
                    onSubmitted: _addTag,
                  ),
                ),
                IconButton(
                  icon: const Icon(LineIcons.plus),
                  onPressed: () => _addTag(_tagInputController.text),
                ),
              ],
            ),
            ValueListenableBuilder<List<String>>(
              valueListenable: _tagsNotifier,
              builder: (_, tags, __) {
                if (tags.isEmpty) return const SizedBox.shrink();
                return Wrap(
                  spacing: 6,
                  children: tags
                      .map((t) => Chip(
                            label: Text(t),
                            onDeleted: () {
                              final copy =
                                  List<String>.from(_tagsNotifier.value);
                              copy.remove(t);
                              _tagsNotifier.value = copy;
                            },
                          ))
                      .toList(),
                );
              },
            ),
            const SizedBox(height: 8),
            Expanded(
              child: QuillEditor.basic(
                configurations: QuillEditorConfigurations(
                  controller: _controller,
                  sharedConfigurations: const QuillSharedConfigurations(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addTag(String raw) {
    final tag = raw.trim();
    if (tag.isEmpty) return;
    final copy = List<String>.from(_tagsNotifier.value);
    if (!copy.contains(tag)) copy.add(tag);
    _tagsNotifier.value = copy;
    _tagInputController.clear();
  }

  Future<void> _saveTemplate() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      CustomSnackBar.show(context, 'Title required', isSuccess: false);
      return;
    }
    String contentJson;
    try {
      contentJson = jsonEncode(_controller.document.toDelta().toJson());
    } catch (_) {
      contentJson = _controller.document.toPlainText();
    }

    if (widget.template == null) {
      final t = NoteTemplate(
        templateId: generateUuid(),
        title: title,
        contentJson: contentJson,
        tags: _tagsNotifier.value,
      );
      await TemplateRepo.createTemplate(t);
      if (mounted) CustomSnackBar.show(context, 'Template created');
    } else {
      widget.template!
        ..title = title
        ..contentJson = contentJson
        ..tags = _tagsNotifier.value
        ..updatedAt = DateTime.now();
      await TemplateRepo.updateTemplate(widget.template!);
      if (mounted) CustomSnackBar.show(context, 'Template updated');
    }
    if (mounted) Navigator.pop(context);
  }
}
