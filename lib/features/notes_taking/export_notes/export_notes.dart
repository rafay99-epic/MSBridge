// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_quill/flutter_quill.dart';
import 'package:line_icons/line_icons.dart';

// Project imports:
import 'package:msbridge/core/file_convters/markdown/markdown_convter.dart';
import 'package:msbridge/core/file_convters/pdf/pdfconvter.dart';

void showExportOptions(
  BuildContext context,
  ThemeData theme,
  TextEditingController titleController,
  QuillController controller,
) {
  showModalBottomSheet(
    context: context,
    backgroundColor: theme.colorScheme.surface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) {
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
                  'Export Options',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 20),
                // Export options
                _buildExportAction(
                  icon: LineIcons.pdfFileAlt,
                  title: 'Export to PDF',
                  subtitle: 'Export your note as a PDF document',
                  onTap: () {
                    Navigator.pop(context);
                    PdfExporter.exportToPdf(
                        context, titleController.text.trim(), controller);
                  },
                  theme: theme,
                ),
                const SizedBox(height: 12),
                _buildExportAction(
                  icon: LineIcons.markdown,
                  title: 'Export to Markdown',
                  subtitle: 'Export your note as a Markdown file',
                  onTap: () {
                    Navigator.pop(context);
                    MarkdownExporter.exportToMarkdown(
                        context, titleController.text.trim(), controller);
                  },
                  theme: theme,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      );
    },
  );
}

Widget _buildExportAction({
  required IconData icon,
  required String title,
  required String subtitle,
  required VoidCallback onTap,
  required ThemeData theme,
}) {
  return Material(
    color: Colors.transparent,
    child: InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 24,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    ),
  );
}
