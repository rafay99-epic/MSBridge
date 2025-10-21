// Flutter imports:
import 'package:flutter/material.dart';

Widget buildProgressBar(ThemeData theme, double scrollProgress) {
  return SizedBox(
    height: 4,
    child: LinearProgressIndicator(
      value: scrollProgress.clamp(0.0, 1.0).toDouble(),
      minHeight: 4,
      backgroundColor: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
      valueColor: AlwaysStoppedAnimation<Color?>(
        theme.colorScheme.primary.withValues(alpha: 0.9),
      ),
    ),
  );
}
