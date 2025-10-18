// Dart imports:
import 'dart:convert';

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_bugfender/flutter_bugfender.dart';
import 'package:flutter_quill/flutter_quill.dart';

class OptimizedBuildContent extends StatefulWidget {
  const OptimizedBuildContent({
    super.key,
    required this.content,
    required this.theme,
  });

  final String content;
  final ThemeData theme;

  @override
  State<OptimizedBuildContent> createState() => _OptimizedBuildContentState();
}

class _OptimizedBuildContentState extends State<OptimizedBuildContent> {
  Widget? _contentWidget;
  String? _lastContent;

  @override
  void initState() {
    super.initState();
    _lastContent = widget.content;
    _contentWidget = _buildContentWidget();
  }

  @override
  void didUpdateWidget(OptimizedBuildContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.content != widget.content) {
      _lastContent = widget.content;
      _contentWidget = _buildContentWidget();
    }
  }

  Widget _buildContentWidget() {
    try {
      final jsonResult = jsonDecode(widget.content);
      if (jsonResult is List) {
        final document = Document.fromJson(jsonResult);
        return AbsorbPointer(
          child: QuillEditor.basic(
            controller: QuillController(
              document: document,
              selection: const TextSelection.collapsed(offset: 0),
            ),
          ),
        );
      } else {
        return Text(
          widget.content,
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
          style: widget.theme.textTheme.bodyMedium?.copyWith(
            color: widget.theme.colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      FlutterBugfender.sendCrash(
          'Error building content: $e', StackTrace.current.toString());
      return Text(
        widget.content,
        maxLines: 4,
        overflow: TextOverflow.ellipsis,
        style: widget.theme.textTheme.bodyMedium?.copyWith(
          color: widget.theme.colorScheme.primary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ensure content widget is initialized and up to date
    if (_contentWidget == null || _lastContent != widget.content) {
      _lastContent = widget.content;
      _contentWidget = _buildContentWidget();
    }
    return _contentWidget!;
  }
}
