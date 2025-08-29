import 'package:flutter/material.dart';

Widget buildSubsectionHeader(
    BuildContext context, String title, IconData icon) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;

  return Row(
    children: [
      Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: colorScheme.secondary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          icon,
          size: 16,
          color: colorScheme.secondary,
        ),
      ),
      const SizedBox(width: 8),
      Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: colorScheme.secondary,
        ),
      ),
    ],
  );
}
