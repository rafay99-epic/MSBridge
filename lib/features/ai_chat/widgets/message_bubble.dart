// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:line_icons/line_icons.dart';

// Project imports:
import 'package:msbridge/core/ai/chat_provider.dart';
import 'package:msbridge/features/ai_chat/optimized_markdown.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({super.key, required this.message});
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bool isUser = message.fromUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: RepaintBoundary(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment:
              isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            if (!isUser) ...[
              _buildAvatar(context, colorScheme, false),
              const SizedBox(width: 12),
            ],
            Flexible(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.78,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: isUser
                      ? colorScheme.primary
                      : message.isError
                          ? colorScheme.errorContainer
                          : colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(20).copyWith(
                    bottomLeft: isUser
                        ? const Radius.circular(20)
                        : const Radius.circular(6),
                    bottomRight: isUser
                        ? const Radius.circular(6)
                        : const Radius.circular(20),
                  ),
                  border: Border.all(
                    color: isUser
                        ? colorScheme.primary
                        : message.isError
                            ? colorScheme.error.withValues(alpha: 0.3)
                            : colorScheme.outline.withValues(alpha: 0.15),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isUser
                          ? colorScheme.primary.withValues(alpha: 0.12)
                          : colorScheme.shadow.withValues(alpha: 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: _buildContent(theme, colorScheme, isUser),
              ),
            ),
            if (isUser) ...[
              const SizedBox(width: 12),
              _buildAvatar(context, colorScheme, true),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(
      BuildContext context, ColorScheme colorScheme, bool isUser) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isUser
              ? [
                  colorScheme.primary,
                  colorScheme.primary.withValues(alpha: 0.8)
                ]
              : message.isError
                  ? [
                      colorScheme.error,
                      colorScheme.error.withValues(alpha: 0.8)
                    ]
                  : [
                      colorScheme.primary,
                      colorScheme.primary.withValues(alpha: 0.8),
                    ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: (isUser ? colorScheme.primary : colorScheme.error)
                .withValues(alpha: 0.15),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Icon(
        isUser
            ? LineIcons.user
            : message.isError
                ? LineIcons.exclamationTriangle
                : LineIcons.robot,
        color: Colors.white,
        size: 18,
      ),
    );
  }

  Widget _buildContent(ThemeData theme, ColorScheme colorScheme, bool isUser) {
    if (isUser) {
      return SelectableText(
        message.text,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: colorScheme.onPrimary,
          fontWeight: FontWeight.w500,
          height: 1.4,
        ),
      );
    }

    if (message.isError) {
      return Text(
        message.text,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: colorScheme.onErrorContainer,
          fontWeight: FontWeight.w500,
          height: 1.4,
        ),
      );
    }

    return OptimizedMarkdownBody(
      data: message.text,
      styleSheet: MarkdownStyleSheet(
        p: theme.textTheme.bodyLarge?.copyWith(
          color: colorScheme.onSurface,
          height: 1.5,
          fontWeight: FontWeight.w400,
        ),
        h1: theme.textTheme.headlineSmall?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w700,
          height: 1.3,
        ),
        h2: theme.textTheme.titleLarge?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w600,
          height: 1.3,
        ),
        h3: theme.textTheme.titleMedium?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w600,
          height: 1.3,
        ),
        code: theme.textTheme.bodyMedium?.copyWith(
          backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
          color: colorScheme.primary,
          fontFamily: 'monospace',
          fontWeight: FontWeight.w500,
        ),
        codeblockDecoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        blockquoteDecoration: BoxDecoration(
          color: colorScheme.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border(
            left: BorderSide(
              color: colorScheme.primary.withValues(alpha: 0.3),
              width: 3,
            ),
          ),
        ),
        blockquotePadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }
}
