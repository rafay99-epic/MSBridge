import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bugfender/flutter_bugfender.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:msbridge/widgets/snakbar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:msbridge/core/permissions/permission.dart';

class MarkdownExporter {
  static Future<void> exportToMarkdown(
      BuildContext context, String title, QuillController controller) async {
    final content = controller.document.toPlainText().trim();

    if (title.isEmpty || content.isEmpty) {
      CustomSnackBar.show(context, "Title or content is empty.");
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
        CustomSnackBar.show(context, "Could not find the downloads directory.");
        return;
      }

      final file = File('${downloadsDirectory.path}/$title.md');
      await file.writeAsString(content);

      CustomSnackBar.show(context, "Markdown saved to ${file.path}");
    } catch (e) {
      FlutterBugfender.sendCrash(
          'Error creating Markdown: $e', StackTrace.current.toString());
      FlutterBugfender.error(
        'Error creating Markdown: $e',
      );
      CustomSnackBar.show(context, "Error creating Markdown: $e");
    }
  }
}
