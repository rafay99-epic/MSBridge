import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:msbridge/widgets/snakbar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:msbridge/core/permissions/permission.dart';

class PdfExporter {
  static Future<void> exportToPdf(
      BuildContext context, String title, QuillController controller) async {
    if (title.isEmpty) {
      CustomSnackBar.show(context, "Title is empty.");
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

      final file = File('${downloadsDirectory.path}/$title.pdf');
      final pdf = pw.Document();

      pdf.addPage(pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(title,
                  style: pw.TextStyle(
                      fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Text(controller.document.toPlainText().trim()),
            ],
          );
        },
      ));

      await file.writeAsBytes(await pdf.save());

      CustomSnackBar.show(context, "PDF saved to ${file.path}");
    } catch (e) {
      CustomSnackBar.show(context, "Error creating PDF: $e");
    }
  }
}
