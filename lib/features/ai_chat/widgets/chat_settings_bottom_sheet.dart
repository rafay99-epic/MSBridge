// Dart imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:msbridge/core/ai/chat_provider.dart';
import 'package:msbridge/core/provider/ai_consent_provider.dart';
import 'package:msbridge/features/ai_chat/widgets/settings/consent_toggle_row.dart';
import 'package:msbridge/features/ai_chat/widgets/settings/include_chips_section.dart';
import 'package:msbridge/features/ai_chat/widgets/settings/session_status_section.dart';
import 'package:msbridge/features/ai_chat/widgets/settings/settings_actions_row.dart';

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
                    ConsentToggleRow(
                      aiConsentProvider: aiConsentProvider,
                      onConsentToggleChanged: onConsentToggleChanged,
                    ),
                    const SizedBox(height: 24),
                    IncludeChipsSection(
                      aiConsentProvider: aiConsentProvider,
                      includePersonal: includePersonal,
                      includeMsNotes: includeMsNotes,
                      onIncludePersonalChanged: onIncludePersonalChanged,
                      onIncludeMsNotesChanged: onIncludeMsNotesChanged,
                    ),
                    const SizedBox(height: 24),
                    SessionStatusSection(chatProvider: chatProvider),
                    const SizedBox(height: 24),
                    SettingsActionsRow(
                      onShowChatHistory: onShowChatHistory,
                      onClearChat: onClearChat,
                      chatProvider: chatProvider,
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
