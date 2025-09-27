import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:msbridge/features/ai_summary/ai_summary_display.dart';

Widget buildSummaryText(
    BuildContext context, String? aiSummary, bool isGeneratingSummary) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;

  return Container(
    decoration: BoxDecoration(
      color: colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: colorScheme.primary.withValues(alpha: 0.1),
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: colorScheme.primary.withValues(alpha: 0.05),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: isGeneratingSummary
          ? Container(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      LineIcons.brain,
                      color: colorScheme.primary,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Generating AI Summary...',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Analyzing your notes with advanced AI',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.primary.withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(colorScheme.primary),
                    ),
                  ),
                ],
              ),
            )
          : aiSummary == null || aiSummary.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: colorScheme.outline.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          LineIcons.fileAlt,
                          color: colorScheme.outline,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'No Summary Available',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: colorScheme.outline,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Generate an AI summary to see it here',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.outline.withValues(alpha: 0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : AiSummaryDisplay(aiSummary: aiSummary),
    ),
  );
}
