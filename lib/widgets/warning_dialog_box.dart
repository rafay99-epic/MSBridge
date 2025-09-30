// Flutter imports:
import 'package:flutter/material.dart';

// Modern, theme-aware confirmation dialog used across the app.
// Keeps backward-compatible signature and adds optional styling controls.
void showConfirmationDialog(
  BuildContext context,
  ThemeData theme,
  VoidCallback action,
  String title,
  String description, {
  String confirmButtonText = "Confirm",
  bool isDestructive = false,
  IconData? icon,
}) {
  final ColorScheme colors = theme.colorScheme;
  final Color accent = isDestructive ? colors.error : colors.secondary;
  final Color onAccent = isDestructive ? colors.onError : colors.onSecondary;

  showDialog(
    context: context,
    barrierColor: colors.shadow.withValues(alpha: 0.4),
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: colors.surface,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.outline.withValues(alpha: 0.12)),
        ),
        titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon ??
                    (isDestructive
                        ? Icons.warning_amber_rounded
                        : Icons.help_outline),
                color: accent,
                size: 28,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: Text(
          description,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colors.onSurface.withValues(alpha: 0.8),
            height: 1.4,
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: colors.primary,
              textStyle: theme.textTheme.labelLarge,
            ),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Cancel"),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: onAccent,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              textStyle: theme.textTheme.labelLarge,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              Navigator.of(context).pop();
              action();
            },
            icon: Icon(
                isDestructive
                    ? Icons.delete_outline
                    : Icons.check_circle_outline,
                size: 18),
            label: Text(confirmButtonText),
          ),
        ],
      );
    },
  );
}
