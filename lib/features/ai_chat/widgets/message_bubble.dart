import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
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
      padding: const EdgeInsets.only(bottom: 16),
      child: RepaintBoundary(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment:
              isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            if (!isUser) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: message.isError
                      ? colorScheme.error.withValues(alpha: 0.15)
                      : colorScheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: message.isError
                        ? colorScheme.error.withValues(alpha: 0.3)
                        : colorScheme.primary.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  message.isError
                      ? LineIcons.exclamationTriangle
                      : LineIcons.robot,
                  color:
                      message.isError ? colorScheme.error : colorScheme.primary,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                ),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isUser
                      ? colorScheme.primary
                      : message.isError
                          ? colorScheme.errorContainer
                          : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16).copyWith(
                    bottomLeft: isUser
                        ? const Radius.circular(16)
                        : const Radius.circular(4),
                    bottomRight: isUser
                        ? const Radius.circular(4)
                        : const Radius.circular(16),
                  ),
                  border: Border.all(
                    color: isUser
                        ? colorScheme.primary
                        : message.isError
                            ? colorScheme.error
                            : colorScheme.primary.withValues(alpha: 0.4),
                    width: message.isError ? 2 : 2.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isUser
                          ? colorScheme.primary.withValues(alpha: 0.2)
                          : colorScheme.primary.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: _buildContent(theme, colorScheme, isUser),
              ),
            ),
            if (isUser) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  LineIcons.user,
                  color: colorScheme.primary,
                  size: 16,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContent(ThemeData theme, ColorScheme colorScheme, bool isUser) {
    if (isUser) {
      return SelectableText(
        message.text,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onPrimary,
          fontWeight: FontWeight.w500,
        ),
      );
    }

    if (message.isError) {
      return Text(
        message.text,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onErrorContainer,
          fontWeight: FontWeight.w500,
        ),
      );
    }

    return OptimizedMarkdownBody(
      data: message.text,
      styleSheet: MarkdownStyleSheet(
        p: theme.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurface,
          height: 1.5,
          fontWeight: FontWeight.w500,
        ),
        h1: theme.textTheme.headlineSmall?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
        h2: theme.textTheme.titleLarge?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
        h3: theme.textTheme.titleMedium?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
        code: theme.textTheme.bodyMedium?.copyWith(
          backgroundColor: colorScheme.primary.withValues(alpha: 0.15),
          color: colorScheme.onSurface,
          fontFamily: 'monospace',
          fontWeight: FontWeight.w600,
        ),
        codeblockDecoration: BoxDecoration(
          color: colorScheme.primary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: colorScheme.primary.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
    );
  }
}
