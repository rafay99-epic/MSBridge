import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bugfender/flutter_bugfender.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:msbridge/core/database/note_taking/note_taking.dart';
import 'package:msbridge/features/notes_taking/read/widgets/is_quil_json.dart';
import 'package:msbridge/features/notes_taking/read/widgets/read_header.dart';
import 'package:msbridge/features/notes_taking/read/widgets/read_content.dart';
import 'package:msbridge/widgets/appbar.dart';
import 'package:line_icons/line_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class ReadNotePage extends StatefulWidget {
  const ReadNotePage({super.key, required this.note});

  final NoteTakingModel note;

  @override
  State<ReadNotePage> createState() => _ReadNotePageState();
}

class _ReadNotePageState extends State<ReadNotePage> {
  static const String _textScalePrefKey = 'read_mode_text_scale';
  static const String _keepAwakePrefKey = 'read_mode_keep_awake';
  double _textScale = 1.0;
  bool _keepAwake = false;

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  double _scrollProgress = 0.0; // 0..1

  @override
  void initState() {
    super.initState();
    loadTextScale();
    loadKeepAwake();
    _scrollController.addListener(_updateScrollProgress);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateScrollProgress);
    _scrollController.dispose();
    _searchController.dispose();
    WakelockPlus.disable();

    super.dispose();
  }

  Future<void> loadTextScale() async {
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

  Future<void> loadKeepAwake() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final bool? k = prefs.getBool(_keepAwakePrefKey);
      if (!mounted) return;
      setState(() {
        _keepAwake = k ?? false;
      });
      await WakelockPlus.toggle(enable: _keepAwake);
      FlutterBugfender.log('ReadMode: wakelock loaded -> $_keepAwake');
    } catch (e) {
      FlutterBugfender.sendCrash(
          'Error loading keep awake: $e', StackTrace.current.toString());
    }
  }

  Future<void> saveTextScale(double value) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_textScalePrefKey, value);
    } catch (e) {
      FlutterBugfender.sendCrash(
          'Error saving text scale: $e', StackTrace.current.toString());
    }
  }

  Future<void> saveKeepAwake(bool value) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keepAwakePrefKey, value);
      await WakelockPlus.toggle(enable: value);
      FlutterBugfender.log('ReadMode: wakelock saved and applied -> $value');
    } catch (e) {
      FlutterBugfender.sendCrash(
          'Error saving keep awake: $e', StackTrace.current.toString());
    }
  }

  void _updateScrollProgress() {
    if (!_scrollController.hasClients) return;
    final double max = _scrollController.position.maxScrollExtent;
    final double offset = _scrollController.offset.clamp(0, max);
    final double progress = max > 0 ? offset / max : 0.0;
    if (progress != _scrollProgress && mounted) {
      setState(() => _scrollProgress = progress);
    }
  }

  Document buildDocument(String content) {
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
    final bool renderQuill = isQuillJson(widget.note.noteContent);

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
              theme.colorScheme.surface.withValues(alpha: 0.95),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ReadHeader(note: widget.note, theme: theme),
                  const SizedBox(height: 24),
                  ReadContent(
                    renderQuill: renderQuill,
                    theme: theme,
                    textScale: _textScale,
                    plainText: widget.note.noteContent,
                    buildDocument: buildDocument,
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildProgressBar(theme),
    );
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
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
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
            StatefulBuilder(builder: (context, setStateSheet) {
              return SwitchListTile(
                secondary:
                    Icon(Icons.bolt_rounded, color: theme.colorScheme.primary),
                title: const Text('Keep screen awake while reading'),
                value: _keepAwake,
                onChanged: (v) async {
                  setStateSheet(() => _keepAwake = v);
                  setState(() {});
                  FlutterBugfender.log('ReadMode: keepAwake toggled -> $v');
                  await saveKeepAwake(v);
                },
              );
            }),
            const SizedBox(height: 8),
            ListTile(
              leading:
                  Icon(LineIcons.textHeight, color: theme.colorScheme.primary),
              title: const Text('Font Size'),
              subtitle:
                  Text('Current: ${(16 * _textScale).toStringAsFixed(0)} pt'),
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
                    await saveTextScale(v);
                  },
                  min: 0.8,
                  max: 1.8,
                  divisions: 10,
                  label: (16 * _textScale).toStringAsFixed(0),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(ThemeData theme) {
    return SizedBox(
      height: 4,
      child: LinearProgressIndicator(
        value: _scrollProgress.clamp(0, 1),
        minHeight: 4,
        backgroundColor:
            theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
        valueColor: AlwaysStoppedAnimation<Color>(
          theme.colorScheme.primary.withValues(alpha: 0.9),
        ),
      ),
    );
  }
}
