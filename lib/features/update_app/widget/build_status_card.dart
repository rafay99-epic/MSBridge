// Flutter imports:
import 'package:flutter/material.dart';

Widget buildStatusCard(
  BuildContext context,
  ColorScheme colorScheme,
  ThemeData theme, {
  required bool isError,
  required String title,
  required String message,
  required IconData icon,
  required Color color,
}) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: color.withValues(alpha: 0.4),
        width: 2,
      ),
      boxShadow: [
        BoxShadow(
          color: color.withValues(alpha: 0.1),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
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
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: color.withValues(alpha: 0.8),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
