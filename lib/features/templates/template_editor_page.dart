// Dart imports:
import 'dart:convert';

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_bugfender/flutter_bugfender.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:line_icons/line_icons.dart';

// Project imports:
import 'package:msbridge/core/database/templates/note_template.dart';
import 'package:msbridge/core/repo/template_repo.dart';
import 'package:msbridge/features/templates/widgets/templates_widgets.dart';
import 'package:msbridge/utils/uuid.dart';
import 'package:msbridge/widgets/snakbar.dart';

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
      } catch (e) {
        FlutterBugfender.sendCrash('Failed to decode template content.',
            StackTrace.current.toString());
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
                    child: SafeArea(
                      child: QuillEditor.basic(
                        controller: _controller,
                        focusNode: _quillFocusNode,
                        config: QuillEditorConfig(
                          disableClipboard: false,
                          autoFocus: true,
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
                      ),
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
                                color: theme.colorScheme.shadow
                                    .withValues(alpha: 0.06),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                            border: Border.all(
                              color: theme.colorScheme.outlineVariant
                                  .withValues(alpha: 0.6),
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: SafeArea(
                              child: QuillSimpleToolbar(
                                controller: _controller,
                                config: const QuillSimpleToolbarConfig(
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
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  void _addTag(String raw) {
    final String tag = raw.trim();
    if (tag.isEmpty) return;
    final List<String> copy = List<String>.from(_tagsNotifier.value);
    if (!copy.contains(tag)) copy.add(tag);
    _tagsNotifier.value = copy;
    _tagInputController.clear();
  }

  Future<void> _saveTemplate() async {
    final String title = _titleController.text.trim();
    if (title.isEmpty) {
      CustomSnackBar.show(context, 'Title required', isSuccess: false);
      return;
    }
    String contentJson;
    try {
      contentJson = jsonEncode(_controller.document.toDelta().toJson());
    } catch (e) {
      FlutterBugfender.sendCrash(
          'Failed to encode template content.', StackTrace.current.toString());
      FlutterBugfender.error('Failed to encode template content.');
      final Document fallbackDoc = Document()
        ..insert(0, _controller.document.toPlainText());
      contentJson = jsonEncode(fallbackDoc.toDelta().toJson());
    }
    if (widget.template == null) {
      final NoteTemplate t = NoteTemplate(
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
