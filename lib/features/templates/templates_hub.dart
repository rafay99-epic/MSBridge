// Flutter imports:
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Package imports:
import 'package:hive_flutter/hive_flutter.dart';
import 'package:line_icons/line_icons.dart';

// Project imports:
import 'package:msbridge/core/database/templates/note_template.dart';
import 'package:msbridge/core/repo/template_repo.dart';
import 'package:msbridge/features/notes_taking/create/create_note.dart';
import 'package:msbridge/features/templates/widgets/templates_widgets.dart';
import 'package:msbridge/utils/empty_ui.dart';
import 'package:msbridge/widgets/appbar.dart';
import 'package:msbridge/widgets/snakbar.dart';
import 'package:msbridge/features/templates/template_editor_page.dart';
import 'package:msbridge/widgets/warning_dialog_box.dart';

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
