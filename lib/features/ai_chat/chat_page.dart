// Dart imports:

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_bugfender/flutter_bugfender.dart';
// markdown used inside widgets
import 'package:line_icons/line_icons.dart';
import 'package:provider/provider.dart';

// Project imports:
import 'package:msbridge/core/ai/chat_provider.dart';
import 'package:msbridge/core/provider/ai_consent_provider.dart';
// removed unused imports after refactor
import 'package:msbridge/features/ai_chat_history/chat_history.dart';
import 'package:msbridge/widgets/appbar.dart';
import 'package:msbridge/widgets/snakbar.dart';
import 'package:msbridge/features/ai_chat/widgets/chat_settings_bottom_sheet.dart';
import 'package:msbridge/features/ai_chat/widgets/typing_indicator.dart';
import 'package:msbridge/features/ai_chat/widgets/message_bubble.dart';
import 'package:msbridge/features/ai_chat/widgets/chat_composer.dart';
import 'package:msbridge/features/ai_chat/widgets/empty_state.dart';

// moved ChatSettingsBottomSheet to widgets/chat_settings_bottom_sheet.dart

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
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, chat, _) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (chat.messages.isNotEmpty) {
                    _scrollToBottom();
                  }
                });
                if (chat.messages.isEmpty) {
                  return const ChatEmptyState();
                }
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: chat.messages.length,
                  cacheExtent: 1000,
                  itemBuilder: (context, index) => MessageBubble(
                    message: chat.messages[index],
                  ),
                );
              },
            ),
          ),
          if (_isTyping) TypingIndicator(colorScheme: colorScheme),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: ChatComposer(
              isSending: _isSending,
              controller: _controller,
              onSend: () => _sendMessage(context),
            ),
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
          },
        );
      },
    );
  }

  void _sendMessage(BuildContext context) async {
    final question = _controller.text.trim();
    if (question.isEmpty) return;

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
