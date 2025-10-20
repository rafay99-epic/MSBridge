// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:line_icons/line_icons.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

Widget buildDownloadProgressCard(
  BuildContext context,
  ColorScheme colorScheme,
  ThemeData theme,
  double downloadProgress,
  VoidCallback? cancelDownload,
) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: colorScheme.primary.withValues(alpha: 0.3),
        width: 2,
      ),
      boxShadow: [
        BoxShadow(
          color: colorScheme.shadow.withValues(alpha: 0.2),
          blurRadius: 12,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: Column(
      children: [
        // Progress Icon
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(
              color: colorScheme.primary.withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
          child: Icon(
            LineIcons.clock,
            size: 32,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(height: 16),

        // Progress Bar
        LinearPercentIndicator(
          width: MediaQuery.of(context).size.width * 0.7,
          animation: true,
          lineHeight: 16.0,
          percent: downloadProgress,
          progressColor: colorScheme.primary,
          backgroundColor: colorScheme.primary.withValues(alpha: 0.2),
          barRadius: const Radius.circular(8),
          fillColor: colorScheme.surfaceContainerHighest,
        ),
        const SizedBox(height: 16),

        // Progress Text
        Text(
          "Downloading: ${(downloadProgress * 100).toStringAsFixed(1)}%",
          style: theme.textTheme.titleMedium?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 20),

        // Cancel Button
        TextButton.icon(
          onPressed: cancelDownload,
          icon: Icon(LineIcons.times, color: colorScheme.error),
          label: Text(
            'Cancel Download',
            style: TextStyle(
              color: colorScheme.error,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            backgroundColor: colorScheme.error.withValues(alpha: 0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: colorScheme.error),
            ),
          ),
        ),
      ],
    ),
  );
}
