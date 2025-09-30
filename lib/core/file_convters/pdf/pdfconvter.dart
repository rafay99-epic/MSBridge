// Dart imports:
import 'dart:io';

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_bugfender/flutter_bugfender.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill_to_pdf/flutter_quill_to_pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;

// Project imports:
import 'package:msbridge/core/permissions/permission.dart';
import 'package:msbridge/widgets/snakbar.dart';

class PdfExporter {
  /// Sanitizes a filename by trimming, replacing invalid characters with underscores,
  /// collapsing whitespace, defaulting to 'document' if empty, and truncating to 64 chars.
  static String _safeFileName(String raw) {
    if (raw.isEmpty) return 'document';

    // Trim whitespace
    String sanitized = raw.trim();

    // Replace invalid filesystem characters and newlines with underscores
    sanitized = sanitized.replaceAll(RegExp(r'[<>:"/\\|?*\n\r]'), '_');

    // Collapse multiple whitespace characters into single spaces
    sanitized = sanitized.replaceAll(RegExp(r'\s+'), ' ');

    // Remove leading/trailing spaces after whitespace collapse
    sanitized = sanitized.trim();

    // Default to 'document' if empty after sanitization
    if (sanitized.isEmpty) return 'document';

    // Truncate to 64 characters
    if (sanitized.length > 64) {
      sanitized = sanitized.substring(0, 64);
    }

    return sanitized;
  }

  static Future<void> exportToPdf(
      BuildContext context, String title, QuillController controller) async {
    if (title.isEmpty) {
      CustomSnackBar.show(context, "Title is empty.", isSuccess: false);
      return;
    }

    // Quick sanity check
    if (controller.document.toPlainText().trim().isEmpty) {
      CustomSnackBar.show(context, "Content is empty.", isSuccess: false);
      return;
    }

    bool hasPermission =
        await PermissionHandler.checkAndRequestFilePermission(context);
    if (!hasPermission) {
      return;
    }

    try {
      Directory? downloadsDirectory;
      if (Platform.isAndroid) {
        downloadsDirectory = Directory('/storage/emulated/0/Download');
      } else if (Platform.isIOS) {
        downloadsDirectory = await getApplicationDocumentsDirectory();
      }

      if (downloadsDirectory == null) {
        if (context.mounted) {
          CustomSnackBar.show(
              context, "Could not find the downloads directory.",
              isSuccess: false);
        }
        return;
      }

      // Ensure the downloads directory exists
      if (!downloadsDirectory.existsSync()) {
        if (context.mounted) {
          CustomSnackBar.show(
              context, "Could not find the downloads directory.",
              isSuccess: false);
        }
        downloadsDirectory.createSync(recursive: true);
      }

      final safeFileName = _safeFileName(title);
      final file = File('${downloadsDirectory.path}/$safeFileName.pdf');

      // Build the converter from Quill Delta
      final delta = controller.document.toDelta();
      final pdfConverter = PDFConverter(
        document: delta,
        pageFormat: PDFPageFormat.all(
          width: PDFPageFormat.a4.width,
          height: PDFPageFormat.a4.height,
          margin: 36,
        ),
        documentOptions: DocumentOptions(
          title: title,
          subject: 'Exported from MSBridge',
          author: 'MSBridge',
        ),
        fallbacks: const <pw.Font>[],
      );

      final pw.Document? doc = await pdfConverter.createDocument();
      if (doc == null) {
        if (context.mounted) {
          CustomSnackBar.show(context, "Failed to generate PDF document",
              isSuccess: false);
        }
        return;
      }
      await file.writeAsBytes(await doc.save());

      if (context.mounted) {
        CustomSnackBar.show(context, "PDF saved to ${file.path}",
            isSuccess: true);
      }
    } catch (e) {
      FlutterBugfender.sendCrash(
          'Error creating PDF: $e', StackTrace.current.toString());
      FlutterBugfender.error(
        'Error creating PDF: $e',
      );
      if (context.mounted) {
        CustomSnackBar.show(context, "Error creating PDF: $e",
            isSuccess: false);
      }
    }
  }
}
