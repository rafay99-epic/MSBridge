// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_quill/flutter_quill.dart';
import 'package:line_icons/line_icons.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

// Project imports:
import 'package:msbridge/core/file_convters/markdown/markdown_convter.dart';
import 'package:msbridge/core/file_convters/pdf/pdfconvter.dart';

void showExportOptions(
  BuildContext context,
  ThemeData theme,
  TextEditingController titleController,
  QuillController controller,
) {
  showCupertinoModalBottomSheet(
    backgroundColor: theme.colorScheme.surface,
    context: context,
    builder: (context) => Material(
      color: theme.colorScheme.surface,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              iconColor: theme.colorScheme.primary,
              leading: const Icon(LineIcons.pdfFileAlt),
              title: Text(
                'Export to PDF',
                style: TextStyle(color: theme.colorScheme.primary),
              ),
              onTap: () => {
                PdfExporter.exportToPdf(
                    context, titleController.text.trim(), controller),
                Navigator.pop(context),
              },
            ),
            ListTile(
              iconColor: theme.colorScheme.primary,
              leading: const Icon(LineIcons.markdown),
              title: Text(
                'Export to Markdown',
                style: TextStyle(color: theme.colorScheme.primary),
              ),
              onTap: () {
                Navigator.pop(context);

                MarkdownExporter.exportToMarkdown(
                    context, titleController.text.trim(), controller);
              },
            ),
          ],
        ),
      ),
    ),
  );
}
