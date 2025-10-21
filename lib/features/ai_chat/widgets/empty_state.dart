// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:line_icons/line_icons.dart';

class ChatEmptyState extends StatelessWidget {
  const ChatEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Static AI Avatar (no animation for performance)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary.withValues(alpha: 0.15),
                    colorScheme.primary.withValues(alpha: 0.08),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.2),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                LineIcons.robot,
                size: 72,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 32),
            // Static Welcome Text (no animation for performance)
            Column(
              children: [
                Text(
                  'Start a conversation with AI',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Ask questions about your notes, get summaries,\nor have a general conversation',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            const SizedBox(height: 40),
            // Static Suggestion Chips (no animation for performance)
            Column(
              children: [
                _buildSuggestionChip(
                  context,
                  colorScheme,
                  theme,
                  'Summarize my recent notes',
                  LineIcons.fileAlt,
                ),
                const SizedBox(height: 12),
                _buildSuggestionChip(
                  context,
                  colorScheme,
                  theme,
                  'What are my main topics?',
                  LineIcons.tags,
                ),
                const SizedBox(height: 12),
                _buildSuggestionChip(
                  context,
                  colorScheme,
                  theme,
                  'Help me organize my thoughts',
                  LineIcons.list,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionChip(
    BuildContext context,
    ColorScheme colorScheme,
    ThemeData theme,
    String text,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
