// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:provider/provider.dart';

// Project imports:
import 'package:msbridge/core/provider/note_summary_ai_provider.dart';
import 'package:msbridge/features/ai_summary/widgets/copy_and_close_row.dart';
import 'package:msbridge/features/ai_summary/widgets/summary_box.dart';
import 'package:msbridge/features/ai_summary/widgets/title.dart';

void showAiSummaryBottomSheet(BuildContext context) {
  showCupertinoModalBottomSheet(
    context: context,
    isDismissible: true,
    enableDrag: true,
    builder: (context) {
      return Consumer<NoteSummaryProvider>(
        builder: (context, noteSummaryProvider, _) {
          String? aiSummary = noteSummaryProvider.aiSummary;
          bool isGeneratingSummary = noteSummaryProvider.isGeneratingSummary;

          return Material(
            child: SafeArea(
              child: FractionallySizedBox(
                heightFactor: 0.9,
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Handle bar
                      Container(
                        margin: const EdgeInsets.only(top: 12),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .outline
                              .withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),

                      // Header section
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: buildTitle(context),
                      ),

                      // Summary content
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: buildSummaryText(
                            context,
                            aiSummary,
                            isGeneratingSummary,
                          ),
                        ),
                      ),

                      // Bottom actions
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          border: Border(
                            top: BorderSide(
                              color: Theme.of(context)
                                  .colorScheme
                                  .outline
                                  .withValues(alpha: 0.1),
                              width: 1,
                            ),
                          ),
                        ),
                        child: buildButtonRow(
                            context, aiSummary, isGeneratingSummary),
                      ),
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
