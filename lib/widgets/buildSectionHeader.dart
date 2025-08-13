import 'package:flutter/material.dart';

Widget buildSectionHeader(BuildContext context, String title, IconData icon,
    {bool isDanger = false}) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;

  return Row(
    children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDanger
              ? Colors.red.withOpacity(0.1)
              : colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 20,
          color: isDanger ? Colors.red : colorScheme.primary,
        ),
      ),
      const SizedBox(width: 12),
      Text(
        title,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: isDanger ? Colors.red : colorScheme.primary,
        ),
      ),
    ],
  );
}
