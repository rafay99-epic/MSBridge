import 'package:flutter/material.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:msbridge/core/provider/note_summary_ai_provider.dart';
import 'package:msbridge/features/ai_summary/widgets/copy_and_close_row.dart';
import 'package:msbridge/features/ai_summary/widgets/summary_box.dart';
import 'package:msbridge/features/ai_summary/widgets/title.dart';
import 'package:provider/provider.dart';

void showAiSummaryBottomSheet(BuildContext context) {
  showCupertinoModalBottomSheet(
    context: context,
    builder: (context) {
      return Consumer<NoteSumaryProvider>(
        builder: (context, noteSummaryProvider, _) {
          String? aiSummary = noteSummaryProvider.aiSummary;
          bool isGeneratingSummary = noteSummaryProvider.isGeneratingSummary;

          return Material(
            child: SafeArea(
              child: FractionallySizedBox(
                heightFactor: 0.85,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      buildTitle(context),
                      const SizedBox(height: 16),
                      Expanded(
                        child: buildSummaryText(
                          context,
                          aiSummary,
                          isGeneratingSummary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      buildButtonRow(context, aiSummary, isGeneratingSummary),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );
}
