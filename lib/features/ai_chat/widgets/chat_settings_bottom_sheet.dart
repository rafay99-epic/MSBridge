// Dart imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:line_icons/line_icons.dart';
import 'package:provider/provider.dart';

// Project imports:
import 'package:msbridge/core/ai/chat_provider.dart';
import 'package:msbridge/core/provider/ai_consent_provider.dart';

class ChatSettingsBottomSheet extends StatelessWidget {
  const ChatSettingsBottomSheet({
    super.key,
    required this.includePersonal,
    required this.onIncludePersonalChanged,
    required this.includeMsNotes,
    required this.onIncludeMsNotesChanged,
    required this.onShowChatHistory,
    required this.onClearChat,
    required this.chatProvider,
    required this.aiConsentProvider,
    required this.onConsentToggleChanged,
  });

  final bool includePersonal;
  final ValueChanged<bool> onIncludePersonalChanged;
  final bool includeMsNotes;
  final ValueChanged<bool> onIncludeMsNotesChanged;
  final VoidCallback onShowChatHistory;
  final VoidCallback onClearChat;
  final ChatProvider chatProvider;
  final AiConsentProvider aiConsentProvider;
  final ValueChanged<bool> onConsentToggleChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (BuildContext context, ScrollController scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.outline.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      'AI Chat Settings',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ChangeNotifierProvider.value(
                      value: aiConsentProvider,
                      child: Consumer<AiConsentProvider>(
                        builder: (context, consent, _) {
                          return Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  LineIcons.userShield,
                                  color: colorScheme.primary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'AI can access your notes for better answers',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Switch(
                                value: consent.enabled,
                                onChanged: onConsentToggleChanged,
                                activeThumbColor: colorScheme.primary,
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    ListenableBuilder(
                      listenable: aiConsentProvider,
                      builder: (context, _) {
                        final bool isGlobalConsentEnabled =
                            aiConsentProvider.enabled;

                        Color getChipLabelColor(
                            bool chipSelected, bool isEnabled) {
                          if (isEnabled) {
                            return chipSelected
                                ? colorScheme.primary
                                : colorScheme.onSurface.withValues(alpha: 0.7);
                          } else {
                            return colorScheme.onSurface.withValues(alpha: 0.4);
                          }
                        }

                        Color getChipBorderColor(
                            bool chipSelected, bool isEnabled) {
                          if (isEnabled) {
                            return chipSelected
                                ? colorScheme.primary
                                : colorScheme.outline.withValues(alpha: 0.3);
                          } else {
                            return colorScheme.onSurface.withValues(alpha: 0.2);
                          }
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Include in AI responses:',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurface
                                    .withValues(alpha: 0.7),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                FilterChip(
                                  label: const Text('Personal Notes'),
                                  selected: includePersonal,
                                  onSelected: isGlobalConsentEnabled
                                      ? onIncludePersonalChanged
                                      : null,
                                  selectedColor:
                                      isGlobalConsentEnabled && includePersonal
                                          ? colorScheme.primary
                                              .withValues(alpha: 0.1)
                                          : Colors.transparent,
                                  checkmarkColor:
                                      isGlobalConsentEnabled && includePersonal
                                          ? colorScheme.primary
                                          : Colors.transparent,
                                  labelStyle: TextStyle(
                                    color: getChipLabelColor(includePersonal,
                                        isGlobalConsentEnabled),
                                    fontWeight: includePersonal &&
                                            isGlobalConsentEnabled
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    side: BorderSide(
                                      color: getChipBorderColor(includePersonal,
                                          isGlobalConsentEnabled),
                                    ),
                                  ),
                                ),
                                FilterChip(
                                  label: const Text('MS Notes'),
                                  selected: includeMsNotes,
                                  onSelected: isGlobalConsentEnabled
                                      ? onIncludeMsNotesChanged
                                      : null,
                                  selectedColor:
                                      isGlobalConsentEnabled && includeMsNotes
                                          ? colorScheme.primary
                                              .withValues(alpha: 0.1)
                                          : Colors.transparent,
                                  checkmarkColor:
                                      isGlobalConsentEnabled && includeMsNotes
                                          ? colorScheme.primary
                                          : Colors.transparent,
                                  labelStyle: TextStyle(
                                    color: getChipLabelColor(
                                        includeMsNotes, isGlobalConsentEnabled),
                                    fontWeight:
                                        includeMsNotes && isGlobalConsentEnabled
                                            ? FontWeight.w600
                                            : FontWeight.w500,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    side: BorderSide(
                                      color: getChipBorderColor(includeMsNotes,
                                          isGlobalConsentEnabled),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    ListenableBuilder(
                      listenable: chatProvider,
                      builder: (context, _) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Session Status:',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurface
                                    .withValues(alpha: 0.7),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: chatProvider.hasError
                                    ? colorScheme.error.withValues(alpha: 0.1)
                                    : chatProvider.isLoading
                                        ? colorScheme.primary
                                            .withValues(alpha: 0.1)
                                        : colorScheme.secondary
                                            .withValues(alpha: 0.1),
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
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
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
                            const SizedBox(height: 24),
                            Row(
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
                                      side: BorderSide(
                                          color: colorScheme.primary),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: chatProvider.messages.isNotEmpty
                                        ? onClearChat
                                        : null,
                                    icon: Icon(
                                      LineIcons.trash,
                                      size: 16,
                                      color: chatProvider.messages.isNotEmpty
                                          ? colorScheme.error
                                          : colorScheme.onSurface
                                              .withValues(alpha: 0.3),
                                    ),
                                    label: Text(
                                      'Clear Chat',
                                      style: TextStyle(
                                        color: chatProvider.messages.isNotEmpty
                                            ? colorScheme.error
                                            : colorScheme.onSurface
                                                .withValues(alpha: 0.3),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(
                                        color: chatProvider.messages.isNotEmpty
                                            ? colorScheme.error
                                            : colorScheme.outline
                                                .withValues(alpha: 0.3),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
