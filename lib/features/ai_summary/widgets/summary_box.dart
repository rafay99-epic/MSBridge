import 'package:flutter/material.dart';
import 'package:msbridge/features/ai_summary/ai_summary_display.dart';

Widget buildSummaryText(
    BuildContext context, String? aiSummary, bool isGeneratingSummary) {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
    ),
    child: SingleChildScrollView(
      child: isGeneratingSummary
          ? const Center(
              child: Text('Generating AI Summary...'),
            )
          : AiSummaryDisplay(aiSummary: aiSummary ?? ''),
    ),
  );
}
