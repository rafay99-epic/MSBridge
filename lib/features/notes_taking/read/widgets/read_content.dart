import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

class ReadContent extends StatefulWidget {
  const ReadContent({
    super.key,
    required this.renderQuill,
    required this.theme,
    required this.textScale,
    required this.plainText,
    required this.buildDocument,
  });

  final bool renderQuill;
  final ThemeData theme;
  final double textScale;
  final String plainText;
  final Document Function(String) buildDocument;

  @override
  State<ReadContent> createState() => _ReadContentState();
}

class _ReadContentState extends State<ReadContent> {
  QuillController? _controller;

  @override
  void initState() {
    super.initState();
    if (widget.renderQuill) {
      _initializeController();
    }
  }

  @override
  void didUpdateWidget(ReadContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.renderQuill != oldWidget.renderQuill ||
        widget.plainText != oldWidget.plainText) {
      _disposeController();
      if (widget.renderQuill) {
        _initializeController();
      }
    }
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  void _initializeController() {
    final Document document = widget.buildDocument(widget.plainText);
    _controller = QuillController(
      document: document,
      selection: const TextSelection.collapsed(offset: 0),
    );
  }

  void _disposeController() {
    _controller?.dispose();
    _controller = null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.menu_book_outlined,
              size: 20,
              color: widget.theme.colorScheme.primary.withOpacity(0.7),
            ),
            const SizedBox(width: 8),
            Text(
              'Content',
              style: widget.theme.textTheme.titleMedium?.copyWith(
                color: widget.theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        widget.renderQuill
            ? _buildQuill()
            : SelectableText(
                widget.plainText.isEmpty
                    ? 'No content available'
                    : widget.plainText,
                style: widget.theme.textTheme.bodyLarge?.copyWith(
                  color: widget.theme.colorScheme.onSurface,
                  height: 1.6,
                  fontFamily: 'Poppins',
                  fontSize: 16 * widget.textScale,
                  letterSpacing: 0.2,
                ),
              ),
      ],
    );
  }

  Widget _buildQuill() {
    if (_controller == null) {
      return const SizedBox.shrink();
    }

    final MediaQueryData base = MediaQuery.of(context);
    return MediaQuery(
      data: base.copyWith(textScaler: TextScaler.linear(widget.textScale)),
      child: AbsorbPointer(
        child: QuillEditor.basic(
          controller: _controller!,
          config: const QuillEditorConfig(
            placeholder: 'No content',
            padding: EdgeInsets.zero,
            scrollable: false,
            autoFocus: false,
            expands: false,
            showCursor: false,
          ),
        ),
      ),
    );
  }
}
