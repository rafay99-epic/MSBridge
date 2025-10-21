// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:line_icons/line_icons.dart';

// Project imports:
import 'package:msbridge/core/ai/chat_provider.dart';

class SessionStatusSection extends StatelessWidget {
  const SessionStatusSection({super.key, required this.chatProvider});

  final ChatProvider chatProvider;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return ListenableBuilder(
      listenable: chatProvider,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Session Status:',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: chatProvider.hasError
                    ? colorScheme.error.withValues(alpha: 0.1)
                    : chatProvider.isLoading
                        ? colorScheme.primary.withValues(alpha: 0.1)
                        : colorScheme.secondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: chatProvider.hasError
                      ? colorScheme.error
                      : chatProvider.isLoading
                          ? colorScheme.primary
                          : colorScheme.secondary,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    chatProvider.hasError
                        ? LineIcons.exclamationTriangle
                        : chatProvider.isLoading
                            ? LineIcons.clock
                            : LineIcons.checkCircle,
                    size: 14,
                    color: chatProvider.hasError
                        ? colorScheme.error
                        : chatProvider.isLoading
                            ? colorScheme.primary
                            : colorScheme.secondary,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      chatProvider.sessionStatus,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: chatProvider.hasError
                            ? colorScheme.error
                            : chatProvider.isLoading
                                ? colorScheme.primary
                                : colorScheme.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
