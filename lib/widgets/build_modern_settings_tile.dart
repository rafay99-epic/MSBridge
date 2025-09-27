import 'package:flutter/material.dart';

Widget buildModernSettingsTile(
  BuildContext context, {
  required String title,
  required String subtitle,
  required IconData icon,
  VoidCallback? onTap,
  Widget? trailing,
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
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.primary.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 16),
              trailing,
            ] else if (onTap != null) ...[
              const SizedBox(width: 16),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: colorScheme.primary.withValues(alpha: 0.5),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
