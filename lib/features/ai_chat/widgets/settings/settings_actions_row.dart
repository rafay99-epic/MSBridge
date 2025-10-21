// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:line_icons/line_icons.dart';

// Project imports:
import 'package:msbridge/core/ai/chat_provider.dart';

class SettingsActionsRow extends StatelessWidget {
  const SettingsActionsRow({
    super.key,
    required this.onShowChatHistory,
    required this.onClearChat,
    required this.chatProvider,
  });

  final VoidCallback onShowChatHistory;
  final VoidCallback onClearChat;
  final ChatProvider chatProvider;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onShowChatHistory,
            icon: Icon(
              LineIcons.history,
              size: 16,
              color: colorScheme.primary,
            ),
            label: Text(
              'View History',
              style: TextStyle(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: colorScheme.primary),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: chatProvider.messages.isNotEmpty ? onClearChat : null,
            icon: Icon(
              LineIcons.trash,
              size: 16,
              color: chatProvider.messages.isNotEmpty
                  ? colorScheme.error
                  : colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            label: Text(
              'Clear Chat',
              style: TextStyle(
                color: chatProvider.messages.isNotEmpty
                    ? colorScheme.error
                    : colorScheme.onSurface.withValues(alpha: 0.3),
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: chatProvider.messages.isNotEmpty
                    ? colorScheme.error
                    : colorScheme.outline.withValues(alpha: 0.3),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
