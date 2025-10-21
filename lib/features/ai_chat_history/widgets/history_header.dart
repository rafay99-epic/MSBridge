// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:line_icons/line_icons.dart';
import 'package:provider/provider.dart';

// Project imports:
import 'package:msbridge/core/provider/chat_history_provider.dart';

class HistoryHeader extends StatelessWidget {
  const HistoryHeader({super.key, required this.onClearAll});

  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Icon(LineIcons.history, color: colorScheme.primary, size: 24),
          const SizedBox(width: 12),
          Text(
            'Chat History',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Consumer<ChatHistoryProvider>(
            builder: (context, historyProvider, _) {
              return TextButton.icon(
                onPressed: historyProvider.chatHistories.isNotEmpty
                    ? onClearAll
                    : null,
                icon: Icon(LineIcons.trash, size: 16, color: colorScheme.error),
                label: Text(
                  'Clear All',
                  style: TextStyle(
                    color: colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
