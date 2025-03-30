import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:line_icons/line_icons.dart';
import 'package:msbridge/widgets/snakbar.dart';

Widget buildButtonRow(
    BuildContext context, String? aiSummary, bool isGeneratingSummary) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: [
      ElevatedButton.icon(
        onPressed: aiSummary == null || isGeneratingSummary
            ? null
            : () {
                Clipboard.setData(ClipboardData(text: aiSummary));
                CustomSnackBar.show(context, "Summary copied to clipboard!");
              },
        icon: const Icon(LineIcons.copy, size: 20),
        label: const Text(
          'Copy Summary',
          style: TextStyle(fontSize: 16),
        ),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      ElevatedButton.icon(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(LineIcons.cross, size: 20),
        label: const Text(
          'Close',
          style: TextStyle(fontSize: 16),
        ),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    ],
  );
}
