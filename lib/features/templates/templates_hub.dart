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
import 'package:msbridge/widgets/appbar.dart';
import 'package:msbridge/widgets/snakbar.dart';
import 'package:msbridge/utils/empty_ui.dart';
import 'package:msbridge/widgets/warning_dialog_box.dart';
import 'package:msbridge/features/templates/widgets/templates_widgets.dart';

class TemplatesHubPage extends StatefulWidget {
  const TemplatesHubPage({super.key});

  @override
  State<TemplatesHubPage> createState() => _TemplatesHubPageState();
}

class _TemplatesHubPageState extends State<TemplatesHubPage> {
  String _search = '';
  String? _selectedTemplateId;
  double _contentOpacity = 1.0;

  Future<void> _fadePulse() async {
    if (!mounted) return;
    setState(() => _contentOpacity = 0.6);
    await Future.delayed(const Duration(milliseconds: 120));
    if (!mounted) return;
    setState(() => _contentOpacity = 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: CustomAppBar(
        backbutton: true,
        title: 'Templates',
        actions: [
          IconButton(
            icon: const Icon(LineIcons.plusCircle),
            onPressed: () async {
              _fadePulse();
              await _createNewTemplate();
            },
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
                  TemplatesSearchField(
                    onChanged: (v) => setState(() => _search = v),
                  ),
                  Expanded(
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      opacity: _contentOpacity,
                      child: items.isEmpty
                          ? const EmptyNotesMessage(
                              message: 'No Templates Yet',
                              description:
                                  'Create your first template to save and reuse note formats easily',
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                              itemCount: items.length,
                              itemBuilder: (context, index) {
                                final t = items[index];
                                final isSelected =
                                    t.templateId == _selectedTemplateId;
                                return TemplateListItem(
                                  title: t.title,
                                  tags: t.tags,
                                  isSelected: isSelected,
                                  onTap: () {
                                    if (_selectedTemplateId != null) {
                                      setState(
                                          () => _selectedTemplateId = null);
                                    } else {
                                      _fadePulse();
                                      _applyTemplate(t);
                                    }
                                  },
                                  onLongPress: () {
                                    setState(() {
                                      _selectedTemplateId =
                                          isSelected ? null : t.templateId;
                                    });
                                  },
                                  onEdit: () async {
                                    _fadePulse();
                                    await _editTemplate(t);
                                    if (mounted) {
                                      setState(
                                          () => _selectedTemplateId = null);
                                    }
                                  },
                                  onDelete: () async {
                                    final theme = Theme.of(context);
                                    showConfirmationDialog(
                                      context,
                                      theme,
                                      () async {
                                        _fadePulse();
                                        await _deleteTemplate(t);
                                        if (mounted) {
                                          setState(
                                              () => _selectedTemplateId = null);
                                        }
                                      },
                                      'Delete Template?',
                                      'Are you sure you want to delete this template?',
                                      confirmButtonText: 'Delete',
                                      isDestructive: true,
                                      icon: Icons.delete_outline,
                                    );
                                  },
                                );
                              },
                            ),
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
    await Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const TemplateEditorPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 250),
      ),
    );
  }

  Future<void> _editTemplate(NoteTemplate t) async {
    await Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            TemplateEditorPage(template: t),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 250),
      ),
    );
  }

  Future<void> _deleteTemplate(NoteTemplate t) async {
    await TemplateRepo.deleteTemplate(t);
    if (mounted) CustomSnackBar.show(context, 'Template deleted');
  }

  Future<void> _applyTemplate(NoteTemplate t) async {
    await Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            CreateNote(initialTemplate: t),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 250),
      ),
    );
  }
}

class TemplateEditorPage extends StatefulWidget {
  const TemplateEditorPage({super.key, this.template});
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
  final FocusNode _quillFocusNode = FocusNode();
  final FocusNode _titleFocusNode = FocusNode();
  final FocusNode _tagFocusNode = FocusNode();

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
        // Try interpreting stored content as plain text instead of blanking it
        _controller = QuillController(
          document: Document()..insert(0, widget.template!.contentJson),
          selection: const TextSelection.collapsed(offset: 0),
        );
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
    _quillFocusNode.dispose();
    _titleFocusNode.dispose();
    _tagFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(
          widget.template == null ? 'New Template' : 'Edit Template',
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        elevation: 1,
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.primary,
        actions: [
          IconButton(
            icon: const Icon(LineIcons.save),
            onPressed: _saveTemplate,
            tooltip: 'Save',
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              focusNode: _titleFocusNode,
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
            // Tags list styled like notes
            ValueListenableBuilder<List<String>>(
              valueListenable: _tagsNotifier,
              builder: (_, tags, __) {
                return TagChipsRow(
                  tags: tags,
                  onRemove: (tag) {
                    final copy = List<String>.from(_tagsNotifier.value);
                    copy.remove(tag);
                    _tagsNotifier.value = copy;
                  },
                );
              },
            ),
            // Tag input styled like notes
            TagInputField(
              controller: _tagInputController,
              focusNode: _tagFocusNode,
              onSubmit: _addTag,
            ),
            ValueListenableBuilder<List<String>>(
              valueListenable: _tagsNotifier,
              builder: (_, tags, __) {
                return const SizedBox.shrink();
              },
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: QuillEditor.basic(
                      configurations: QuillEditorConfigurations(
                        controller: _controller,
                        sharedConfigurations: const QuillSharedConfigurations(),
                        placeholder: 'Start composing your template...',
                        expands: true,
                        onTapUp: (_, __) {
                          if (!_quillFocusNode.hasFocus) {
                            FocusScope.of(context)
                                .requestFocus(_quillFocusNode);
                          }
                          return false;
                        },
                      ),
                      focusNode: _quillFocusNode,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 6),
                      child: Listener(
                        onPointerDown: (_) {
                          if (!_quillFocusNode.hasFocus) {
                            FocusScope.of(context)
                                .requestFocus(_quillFocusNode);
                          }
                        },
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    theme.colorScheme.shadow.withOpacity(0.06),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                            border: Border.all(
                              color: theme.colorScheme.outlineVariant
                                  .withOpacity(0.6),
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: QuillToolbar.simple(
                              configurations: QuillSimpleToolbarConfigurations(
                                controller: _controller,
                                sharedConfigurations:
                                    const QuillSharedConfigurations(),
                                multiRowsDisplay: false,
                                toolbarSize: 44,
                                showCodeBlock: true,
                                showQuote: true,
                                showLink: true,
                                showFontSize: true,
                                showFontFamily: true,
                                showIndent: true,
                                showDividers: true,
                                showUnderLineButton: true,
                                showLeftAlignment: true,
                                showCenterAlignment: true,
                                showRightAlignment: true,
                                showJustifyAlignment: true,
                                showHeaderStyle: true,
                                showListNumbers: true,
                                showListBullets: true,
                                showListCheck: true,
                                showStrikeThrough: true,
                                showInlineCode: true,
                                showColorButton: true,
                                showBackgroundColorButton: true,
                                showClearFormat: true,
                                showAlignmentButtons: true,
                                showUndo: true,
                                showRedo: true,
                                showDirection: false,
                                showSearchButton: true,
                                headerStyleType: HeaderStyleType.buttons,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
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
      // Ensure we still persist valid Delta JSON
      final fallbackDoc = Document()
        ..insert(0, _controller.document.toPlainText());
      contentJson = jsonEncode(fallbackDoc.toDelta().toJson());
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
