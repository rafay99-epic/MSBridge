import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';

class EmptyHistory extends StatelessWidget {
  const EmptyHistory({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LineIcons.history,
              size: 64, color: colorScheme.primary.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text(
            'No chat history yet',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.primary.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your conversations will appear here',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.primary.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
