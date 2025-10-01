// Dart imports:
import 'dart:io';

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_bugfender/flutter_bugfender.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:image_picker/image_picker.dart';
import 'package:line_icons/line_icons.dart';
import 'package:provider/provider.dart';

// Project imports:
import 'package:msbridge/core/ai/chat_provider.dart';
import 'package:msbridge/core/provider/ai_consent_provider.dart';
import 'package:msbridge/core/provider/uploadthing_provider.dart';
import 'package:msbridge/features/ai_chat/optimzed_markdown.dart';
import 'package:msbridge/features/ai_chat_history/chat_history.dart';
import 'package:msbridge/widgets/appbar.dart';
import 'package:msbridge/widgets/snakbar.dart';

class ChatSettingsBottomSheet extends StatelessWidget {
  const ChatSettingsBottomSheet({
    super.key,
    required this.includePersonal,
    required this.onIncludePersonalChanged,
    required this.includeMsNotes,
    required this.onIncludeMsNotesChanged,
    required this.onShowChatHistory,
    required this.onClearChat,
    required this.chatProvider, // Passed directly
    required this.aiConsentProvider, // Passed directly
    required this.onConsentToggleChanged, // Callback for global consent toggle
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
              // Draggable handle
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

                    // Consent Card (Global Toggle)
                    ChangeNotifierProvider.value(
                      value:
                          aiConsentProvider, // Provide locally for the Switch to rebuild
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
                                onChanged:
                                    onConsentToggleChanged, // Use the callback from parent
                                activeThumbColor: colorScheme.primary,
                              ),
                            ],
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Filter Chips (Individual Toggles)
                    // Listen to aiConsentProvider directly to disable/enable chips
                    ListenableBuilder(
                      listenable: aiConsentProvider,
                      builder: (context, _) {
                        final bool isGlobalConsentEnabled =
                            aiConsentProvider.enabled;

                        // Helper function to get label color based on enablement and selection
                        Color getChipLabelColor(
                            bool chipSelected, bool isEnabled) {
                          if (isEnabled) {
                            return chipSelected
                                ? colorScheme.primary // Active and selected
                                : colorScheme.onSurface.withValues(
                                    alpha: 0.7); // Active but unselected
                          } else {
                            return colorScheme.onSurface
                                .withValues(alpha: 0.4); // Disabled
                          }
                        }

                        // Helper function for border color based on enablement and selection
                        Color getChipBorderColor(
                            bool chipSelected, bool isEnabled) {
                          if (isEnabled) {
                            return chipSelected
                                ? colorScheme.primary // Active and selected
                                : colorScheme.outline.withValues(
                                    alpha: 0.3); // Active but unselected
                          } else {
                            return colorScheme.onSurface
                                .withValues(alpha: 0.2); // Disabled
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
                                  // 'selected' reflects local state (_includePersonal)
                                  selected: includePersonal,
                                  onSelected: isGlobalConsentEnabled
                                      ? onIncludePersonalChanged
                                      : null, // Disable interaction if global consent is off
                                  selectedColor: isGlobalConsentEnabled &&
                                          includePersonal
                                      ? colorScheme.primary
                                          .withValues(alpha: 0.1)
                                      : Colors
                                          .transparent, // Muted/transparent when unselected or disabled
                                  checkmarkColor: isGlobalConsentEnabled &&
                                          includePersonal
                                      ? colorScheme.primary
                                      : Colors
                                          .transparent, // Muted/transparent when unselected or disabled
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
                                      : null, // Disable interaction if global consent is off
                                  selectedColor: isGlobalConsentEnabled &&
                                          includeMsNotes
                                      ? colorScheme.primary
                                          .withValues(alpha: 0.1)
                                      : Colors
                                          .transparent, // Muted/transparent when unselected or disabled
                                  checkmarkColor: isGlobalConsentEnabled &&
                                          includeMsNotes
                                      ? colorScheme.primary
                                      : Colors
                                          .transparent, // Muted/transparent when unselected or disabled
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

                    // Status and Actions Section
                    // Listen to chatProvider directly to update status and enable/disable clear chat
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
                            // Action Buttons
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
                                        horizontal: 12,
                                        vertical: 12,
                                      ),
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
                                        horizontal: 12,
                                        vertical: 12,
                                      ),
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

// --- MAIN CHAT ASSISTANT PAGE ---
class ChatAssistantPage extends StatefulWidget {
  const ChatAssistantPage({super.key});

  @override
  State<ChatAssistantPage> createState() => _ChatAssistantPageState();
}

class _ChatAssistantPageState extends State<ChatAssistantPage>
    with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _includePersonal = false;
  bool _includeMsNotes = false;
  bool _isTyping = false;
  bool _isSending = false; // New state variable for sending status

  @override
  void initState() {
    super.initState();

    // IMPORTANT: Set initial state of include flags based on consent when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final aiConsentProvider =
          Provider.of<AiConsentProvider>(context, listen: false);
      if (aiConsentProvider.enabled) {
        setState(() {
          _includePersonal = true;
          _includeMsNotes = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200), // Faster animation
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      // Let the chat page resize so the input stays above the keyboard,
      // without moving the global bottom nav (handled by Home)
      resizeToAvoidBottomInset: true,
      backgroundColor: colorScheme.surface,
      appBar: CustomAppBar(
        title: "Ask AI",
        backbutton: false,
        actions: [
          IconButton(
            icon: Icon(
              LineIcons.cog,
              color: colorScheme.onSurface,
              size: 24,
            ),
            onPressed: () => _showChatSettingsBottomSheet(context),
            tooltip: 'AI Chat Settings',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Chat Messages
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, chat, _) {
                // Auto-scroll to bottom when new messages arrive
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (chat.messages.isNotEmpty) {
                    _scrollToBottom();
                  }
                });

                return chat.messages.isEmpty
                    ? _buildEmptyState(context, colorScheme, theme)
                    : _buildChatMessages(context, chat, colorScheme, theme);
              },
            ),
          ),

          if (_isTyping) _buildTypingIndicator(context, colorScheme),

          // Message Composer
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: _buildComposer(context, colorScheme, theme),
          ),
        ],
      ),
    );
  }

  // Method to show the settings bottom sheet
  void _showChatSettingsBottomSheet(BuildContext context) {
    // Retrieve Provider instances from this context (which should have access from main.dart)
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final aiConsentProvider =
        Provider.of<AiConsentProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor:
          Colors.transparent, // Important for custom rounded corners
      builder: (ctx) {
        return ChatSettingsBottomSheet(
          includePersonal: _includePersonal,
          onIncludePersonalChanged: (v) {
            setState(() => _includePersonal = v);
          },
          includeMsNotes: _includeMsNotes,
          onIncludeMsNotesChanged: (v) {
            setState(() => _includeMsNotes = v);
          },
          onShowChatHistory: () {
            Navigator.pop(ctx); // Close settings sheet
            _showChatHistory(context); // Open history sheet
          },
          onClearChat: () {
            Navigator.pop(ctx); // Close settings sheet
            _clearChat(context); // Clear chat
          },
          chatProvider: chatProvider, // Pass the instance
          aiConsentProvider: aiConsentProvider, // Pass the instance
          onConsentToggleChanged: (newValue) async {
            // Update the actual provider's state
            await aiConsentProvider.setEnabled(newValue);

            // Update the local include flags and trigger rebuild of the main page if needed
            setState(() {
              if (newValue) {
                // If consent is enabled, default both individual options to true
                _includePersonal = true;
                _includeMsNotes = true;
                CustomSnackBar.show(context,
                    'AI access to notes enabled. You can now select specific notes.');
              } else {
                // If consent is disabled, explicitly disable both individual options
                _includePersonal = false;
                _includeMsNotes = false;
                CustomSnackBar.show(context,
                    'AI access to notes disabled. No notes will be included.');
              }
            });
            // No need to pop ctx here, as the sheet remains open for further interaction.
          },
        );
      },
    );
  }

  // --- REST OF CHAT ASSISTANT PAGE WIDGETS ---
  Widget _buildEmptyState(
      BuildContext context, ColorScheme colorScheme, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              LineIcons.robot,
              size: 64,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Start a conversation with AI',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ask questions about your notes, get summaries,\nor have a general conversation',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.primary.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Text(
              'Try: "Summarize my recent notes" or "What are my main topics?"',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.primary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatMessages(BuildContext context, ChatProvider chat,
      ColorScheme colorScheme, ThemeData theme) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: chat.messages.length,
      cacheExtent: 1000,
      itemBuilder: (context, index) {
        final message = chat.messages[index];
        final isUser = message.fromUser;

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
                      color: message.isError
                          ? colorScheme.error
                          : colorScheme.primary,
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
                      // Simplify shadow for better performance
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
                    child: _buildMessageContent(
                        context, message, isUser, theme, colorScheme),
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
      },
    );
  }

  Widget _buildMessageContent(BuildContext context, ChatMessage message,
      bool isUser, ThemeData theme, ColorScheme colorScheme) {
    if (isUser) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message.imageUrls.isNotEmpty) ...[
            for (final imgUrl in message.imageUrls)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    imgUrl,
                    height: 180,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 180,
                        color: colorScheme.primary.withValues(alpha: 0.1),
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (_, __, ___) => Text(
                      'Image preview unavailable',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ),
              ),
          ],
          SelectableText(
            message.text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onPrimary,
              fontWeight: FontWeight.w500,
            ),
          )
        ],
      );
    } else if (message.isError) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message.text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onErrorContainer,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () => _retryLastQuestion(context),
                icon: Icon(
                  LineIcons.redo,
                  size: 16,
                  color: colorScheme.error,
                ),
                label: Text(
                  'Retry',
                  style: TextStyle(
                    color: colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: colorScheme.error),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (message.errorDetails != null)
                IconButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Error Details'),
                        content: SelectableText(message.errorDetails!),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: Icon(
                    LineIcons.infoCircle,
                    size: 16,
                    color: colorScheme.error,
                  ),
                  tooltip: 'View Error Details',
                ),
            ],
          ),
        ],
      );
    } else {
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

  Widget _buildTypingIndicator(BuildContext context, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding:
          const EdgeInsets.symmetric(horizontal: 16), // Align with messages
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              LineIcons.robot,
              color: colorScheme.primary,
              size: 16,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(16).copyWith(
                bottomLeft: const Radius.circular(4),
              ),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTypingDot(colorScheme, 0),
                const SizedBox(width: 4),
                _buildTypingDot(colorScheme, 1),
                const SizedBox(width: 4),
                _buildTypingDot(colorScheme, 2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDot(ColorScheme colorScheme, int index) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + (index * 200)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.5 + (0.5 * value),
          child: child!,
        );
      },
      curve: Curves.easeInOutSine,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: colorScheme.primary.withValues(alpha: 0.6),
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Widget _buildComposer(
      BuildContext context, ColorScheme colorScheme, ThemeData theme) {
    final chat = Provider.of<ChatProvider>(context);
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: colorScheme.outline.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (chat.pendingImageUrls.isNotEmpty)
              SizedBox(
                height: 76,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(bottom: 8),
                  itemBuilder: (_, i) {
                    final url = chat.pendingImageUrls[i];
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            url,
                            width: 76,
                            height: 76,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: -6,
                          right: -6,
                          child: Material(
                            color: colorScheme.error,
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: () => chat.removePendingImageUrl(url),
                              child: const Padding(
                                padding: EdgeInsets.all(4),
                                child: Icon(Icons.close,
                                    size: 14, color: Colors.white),
                              ),
                            ),
                          ),
                        )
                      ],
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemCount: chat.pendingImageUrls.length,
                ),
              ),
            Row(
              children: [
                IconButton(
                  onPressed: _isSending ? null : () => _attachImage(context),
                  icon: Icon(LineIcons.image, color: colorScheme.primary),
                  tooltip: 'Attach Image',
                ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: colorScheme.primary.withValues(alpha: 0.4),
                        width: 2.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withValues(alpha: 0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _controller,
                      maxLines: null,
                      enabled: !_isSending, // Disable text field when sending
                      textInputAction: TextInputAction.send,
                      decoration: InputDecoration(
                        hintText: _isSending
                            ? 'Sending message...'
                            : 'Ask AI anything...',
                        hintStyle: TextStyle(
                          color: colorScheme.primary.withValues(alpha: 0.7),
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                      ),
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontSize: 16,
                      ),
                      onSubmitted:
                          _isSending ? null : (_) => _sendMessage(context),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: _isSending
                        ? colorScheme.primary.withValues(alpha: 0.5)
                        : colorScheme.primary,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: _isSending
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  colorScheme.onPrimary),
                            ),
                          )
                        : Icon(
                            LineIcons.paperPlane,
                            color: colorScheme.onPrimary,
                            size: 20,
                          ),
                    onPressed: _isSending ? null : () => _sendMessage(context),
                    style: IconButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _attachImage(BuildContext context) async {
    final prov = Provider.of<UploadThingProvider>(context, listen: false);
    final chat = Provider.of<ChatProvider>(context, listen: false);

    final picker = ImagePicker();
    final x =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (x == null) return;

    final placeholder = ChatMessage(true, 'Uploading image...');

    chat.messages.add(placeholder);
    if (mounted) {
      setState(() {
        _isTyping = true;
      });
    }

    try {
      final url = await prov.uploadImage(File(x.path));

      if (url != null) {
        chat.addPendingImageUrl(url);
        if (context.mounted) {
          CustomSnackBar.show(
              context, 'Image attached. Type your question and send.',
              isSuccess: true);
        }
      } else {
        if (context.mounted) {
          CustomSnackBar.show(context, 'Image upload failed', isSuccess: false);
        }
      }
    } catch (e) {
      FlutterBugfender.error('Image upload failed: $e');
      if (context.mounted) {
        CustomSnackBar.show(context, 'Image upload failed: $e',
            isSuccess: false);
      }
    } finally {
      if (chat.messages.isNotEmpty &&
          identical(chat.messages.last, placeholder)) {
        chat.messages.removeLast();
      }

      if (context.mounted) {
        setState(() {
          _isTyping = false;
        });
      }
    }
  }

  void _sendMessage(BuildContext context) async {
    final question = _controller.text.trim();
    if (question.isEmpty) return;

    // Early return if already sending to prevent parallel sends
    if (_isSending) return;

    final consent = Provider.of<AiConsentProvider>(context, listen: false);
    final chat = Provider.of<ChatProvider>(context, listen: false);

    final canIncludePersonal = consent.enabled && _includePersonal;
    final shouldIncludeMsNotes = consent.enabled && _includeMsNotes;

    if (!consent.enabled && (question.toLowerCase().contains('note'))) {
      CustomSnackBar.show(context,
          'AI access to notes is disabled. Notes cannot be included in this response.',
          isSuccess: false);
    }

    // Set sending flag immediately to prevent parallel sends
    setState(() {
      _isSending = true;
      _isTyping = true;
    });

    try {
      if (!chat.isReady) {
        try {
          await chat.startSession(
            includePersonal: canIncludePersonal,
            includeMsNotes: shouldIncludeMsNotes,
          );

          if (chat.hasError && context.mounted) {
            CustomSnackBar.show(context,
                chat.lastErrorMessage ?? 'Failed to start chat session');
            return;
          }
        } catch (e) {
          FlutterBugfender.error('Error starting session: $e');
          if (context.mounted) {
            CustomSnackBar.show(context, 'Error starting session: $e');
          }
          return;
        }
      }

      final response = await chat.ask(
        question,
        includePersonal: canIncludePersonal,
        includeMsNotes: shouldIncludeMsNotes,
      );

      if (response != null) {
        _controller.clear();
      } else if (chat.hasError && context.mounted) {
        CustomSnackBar.show(context,
            'Failed to get AI response. You can retry using the retry button.');
      }
    } catch (e) {
      FlutterBugfender.error('Unexpected error: $e');
      if (context.mounted) {
        CustomSnackBar.show(context, 'Unexpected error: $e');
      }
    } finally {
      // Always reset both flags in finally block
      if (mounted) {
        setState(() {
          _isSending = false;
          _isTyping = false;
        });
      }
    }
  }

  void _retryLastQuestion(BuildContext context) async {
    final chat = Provider.of<ChatProvider>(context, listen: false);
    if (chat.isLoading) return;

    setState(() {
      _isTyping = true;
    });

    try {
      final response = await chat.retryLastQuestion();

      if (response != null && context.mounted) {
        CustomSnackBar.show(context, 'Retry successful!', isSuccess: true);
      } else if (chat.hasError && context.mounted) {
        CustomSnackBar.show(context, 'Retry failed: ${chat.lastErrorMessage}');
      }
    } catch (e) {
      FlutterBugfender.error('Error during retry: $e');
      if (context.mounted) {
        CustomSnackBar.show(context, 'Error during retry: $e');
      }
    } finally {
      setState(() {
        _isTyping = false;
      });
    }
  }

  void _clearChat(BuildContext context) {
    final chat = Provider.of<ChatProvider>(context, listen: false);
    chat.clearChat();
    if (context.mounted) {
      CustomSnackBar.show(context, 'Chat cleared', isSuccess: true);
    }
  }

  void _showChatHistory(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ChatHistoryBottomSheet(),
    );
  }
}
