import 'package:flutter/material.dart';

Widget buildSettingsTile(
  BuildContext context, {
  required String title,
  required IconData icon,
  String? subtitle,
  VoidCallback? onTap,
}) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;

  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      splashColor: colorScheme.primary.withValues(alpha: 0.1),
      highlightColor: colorScheme.primary.withValues(alpha: 0.05),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 20,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.primary,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.primary.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.chevron_right,
                size: 20,
                color: colorScheme.primary.withValues(alpha: 0.5),
              ),
          ],
        ),
      ),
    ),
  );
}
