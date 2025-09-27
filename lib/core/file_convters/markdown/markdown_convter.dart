import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bugfender/flutter_bugfender.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:markdown_quill/markdown_quill.dart';
import 'package:msbridge/widgets/snakbar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:msbridge/core/permissions/permission.dart';

class MarkdownExporter {
  static String _safeFileName(String title) {
    if (title.isEmpty) return 'note';
    String sanitized = title.trim();

    sanitized = sanitized.replaceAll(RegExp(r'[<>:"/\\|?*\n\r]'), '_');
    sanitized = sanitized.replaceAll(RegExp(r'\s+'), ' ');

    sanitized = sanitized.trim();

    if (sanitized.isEmpty) return 'note';

    if (sanitized.length > 64) {
      sanitized = sanitized.substring(0, 64);
    }

    return sanitized;
  }

  static Future<void> exportToMarkdown(
      BuildContext context, String title, QuillController controller) async {
    final delta = controller.document.toDelta();
    final converter = DeltaToMarkdown();
    final content = converter.convert(delta).trim();

    if (title.isEmpty || content.isEmpty) {
      CustomSnackBar.show(context, "Title or content is empty.",
          isSuccess: false);
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

      final safeFileName = _safeFileName(title);
      final file = File('${downloadsDirectory.path}/$safeFileName.md');
      await file.writeAsString(content);
      if (context.mounted) {
        CustomSnackBar.show(context, "Markdown saved to ${file.path}",
            isSuccess: true);
      }
    } catch (e) {
      FlutterBugfender.sendCrash(
          'Error creating Markdown: $e', StackTrace.current.toString());
      FlutterBugfender.error(
        'Error creating Markdown: $e',
      );
      if (context.mounted) {
        CustomSnackBar.show(context, "Error creating Markdown: $e",
            isSuccess: false);
      }
    }
  }
}
