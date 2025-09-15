import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bugfender/flutter_bugfender.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:msbridge/core/database/note_taking/note_taking.dart';
import 'package:msbridge/widgets/appbar.dart';
import 'package:line_icons/line_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReadNotePage extends StatefulWidget {
  const ReadNotePage({super.key, required this.note});

  final NoteTakingModel note;

  @override
  State<ReadNotePage> createState() => _ReadNotePageState();
}

class _ReadNotePageState extends State<ReadNotePage> {
  static const String _textScalePrefKey = 'read_mode_text_scale';
  double _textScale = 1.0;

  @override
  void initState() {
    super.initState();
    _loadTextScale();
  }

  Future<void> _loadTextScale() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final double? saved = prefs.getDouble(_textScalePrefKey);
      if (!mounted) return;
      setState(() {
        _textScale = (saved != null && saved > 0) ? saved : 1.0;
      });
    } catch (e) {
      FlutterBugfender.sendCrash(
          'Error loading text scale: $e', StackTrace.current.toString());
    }
  }

  Future<void> _saveTextScale(double value) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_textScalePrefKey, value);
    } catch (e) {
      FlutterBugfender.sendCrash(
          'Error saving text scale: $e', StackTrace.current.toString());
    }
  }

  bool _isQuillJson(String content) {
    try {
      final dynamic parsed = jsonDecode(content);
      if (parsed is List) return true;
      if (parsed is Map && parsed['ops'] is List) return true;
      return false;
    } catch (e) {
      FlutterBugfender.sendCrash('Error checking if content is quill json: $e',
          StackTrace.current.toString());
      return false;
    }
  }

  Document _buildDocument(String content) {
    try {
      final dynamic parsed = jsonDecode(content);
      if (parsed is List) {
        return Document.fromJson(parsed);
      }
      if (parsed is Map && parsed['ops'] is List) {
        return Document.fromJson(parsed['ops'] as List<dynamic>);
      }
    } catch (e) {
      FlutterBugfender.sendCrash(
          'Error building document: $e', StackTrace.current.toString());
    }
    return Document()..insert(0, content);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool renderQuill = _isQuillJson(widget.note.noteContent);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: CustomAppBar(
        backbutton: true,
        title: 'Read Notes',
        actions: [
          IconButton(
            tooltip: 'Reading settings',
            icon: const Icon(LineIcons.cog, size: 22),
            onPressed: () => _showReadingSettings(context, theme),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.surface.withOpacity(0.95),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(theme),
                  const SizedBox(height: 24),
                  _buildContentCard(theme, renderQuill),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LineIcons.file,
                size: 24,
                color: theme.colorScheme.primary.withOpacity(0.8),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.note.noteTitle.isEmpty
                      ? 'Untitled Note'
                      : widget.note.noteTitle,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.primary,
                    letterSpacing: -0.5,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                LineIcons.clock,
                size: 16,
                color: theme.colorScheme.secondary.withOpacity(0.7),
              ),
              const SizedBox(width: 8),
              Text(
                'Updated ${_formatDate(widget.note.updatedAt)}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.secondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          if (widget.note.tags.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final String tag in widget.note.tags)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary.withOpacity(0.1),
                          theme.colorScheme.secondary.withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: theme.colorScheme.primary.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LineIcons.tag,
                          size: 14,
                          color: theme.colorScheme.primary.withOpacity(0.7),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          tag,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContentCard(ThemeData theme, bool renderQuill) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              LineIcons.readme,
              size: 20,
              color: theme.colorScheme.primary.withOpacity(0.7),
            ),
            const SizedBox(width: 8),
            Text(
              'Content',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        renderQuill ? _buildQuillReadOnly(theme) : _buildPlainText(theme),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'today at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'yesterday at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _showReadingSettings(BuildContext context, ThemeData theme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Reading Settings',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading:
                  Icon(LineIcons.textHeight, color: theme.colorScheme.primary),
              title: const Text('Font Size'),
              subtitle:
                  Text('Current: ${(16 * _textScale).toStringAsFixed(0)} pt'),
              onTap: () {},
            ),
            StatefulBuilder(
              builder: (context, setStateSheet) {
                return Slider(
                  value: _textScale,
                  onChanged: (v) {
                    if (v < 0.8) v = 0.8;
                    if (v > 1.8) v = 1.8;
                    setStateSheet(() => _textScale = v);
                    setState(() {});
                  },
                  onChangeEnd: (v) async {
                    await _saveTextScale(v);
                  },
                  min: 0.8,
                  max: 1.8,
                  divisions: 10,
                  label: '${(16 * _textScale).toStringAsFixed(0)}',
                );
              },
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: Icon(LineIcons.moon, color: theme.colorScheme.primary),
              title: const Text('Dark Mode'),
              subtitle: const Text('Switch to dark theme for reading'),
              onTap: () {
                Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildQuillReadOnly(ThemeData theme) {
    final Document document = _buildDocument(widget.note.noteContent);
    final QuillController controller = QuillController(
      document: document,
      selection: const TextSelection.collapsed(offset: 0),
    );
    final MediaQueryData base = MediaQuery.of(context);
    return MediaQuery(
      data: base.copyWith(textScaler: TextScaler.linear(_textScale)),
      child: AbsorbPointer(
        child: QuillEditor.basic(
          controller: controller,
          config: QuillEditorConfig(
            placeholder: 'No content',
            padding: EdgeInsets.zero,
            scrollable: true,
            autoFocus: false,
            expands: false,
            showCursor: false,
          ),
        ),
      ),
    );
  }

  Widget _buildPlainText(ThemeData theme) {
    return SelectableText(
      widget.note.noteContent.isEmpty
          ? 'No content available'
          : widget.note.noteContent,
      style: theme.textTheme.bodyLarge?.copyWith(
        color: theme.colorScheme.onSurface,
        height: 1.6,
        fontFamily: 'Poppins',
        fontSize: 16 * _textScale,
        letterSpacing: 0.2,
      ),
    );
  }
}
