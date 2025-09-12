import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bugfender/flutter_bugfender.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill_to_pdf/flutter_quill_to_pdf.dart';
import 'package:msbridge/widgets/snakbar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:msbridge/core/permissions/permission.dart';

class PdfExporter {
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
        CustomSnackBar.show(context, "Could not find the downloads directory.",
            isSuccess: false);
        return;
      }

      final file = File('${downloadsDirectory.path}/$title.pdf');

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
        CustomSnackBar.show(context, "Failed to generate PDF document",
            isSuccess: false);
        return;
      }
      await file.writeAsBytes(await doc.save());

      CustomSnackBar.show(context, "PDF saved to ${file.path}",
          isSuccess: true);
    } catch (e) {
      FlutterBugfender.sendCrash(
          'Error creating PDF: $e', StackTrace.current.toString());
      FlutterBugfender.error(
        'Error creating PDF: $e',
      );
      CustomSnackBar.show(context, "Error creating PDF: $e", isSuccess: false);
    }
  }
}
