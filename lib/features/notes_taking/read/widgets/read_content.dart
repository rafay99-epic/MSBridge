import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

class ReadContent extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.menu_book_outlined,
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
        renderQuill
            ? _buildQuill(theme, context)
            : SelectableText(
                plainText.isEmpty ? 'No content available' : plainText,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface,
                  height: 1.6,
                  fontFamily: 'Poppins',
                  fontSize: 16 * textScale,
                  letterSpacing: 0.2,
                ),
              ),
      ],
    );
  }

  Widget _buildQuill(ThemeData theme, BuildContext context) {
    final Document document = buildDocument(plainText);
    final QuillController controller = QuillController(
      document: document,
      selection: const TextSelection.collapsed(offset: 0),
    );
    final MediaQueryData base = MediaQuery.of(context);
    return MediaQuery(
      data: base.copyWith(textScaler: TextScaler.linear(textScale)),
      child: AbsorbPointer(
        child: QuillEditor.basic(
          controller: controller,
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
