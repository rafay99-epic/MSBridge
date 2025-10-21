// Dart imports:

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_bugfender/flutter_bugfender.dart';
import 'package:line_icons/line_icons.dart';
import 'package:provider/provider.dart';

// Project imports:
import 'package:msbridge/core/ai/chat_provider.dart';
import 'package:msbridge/core/provider/ai_consent_provider.dart';
import 'package:msbridge/features/ai_chat/widgets/chat_composer.dart';
import 'package:msbridge/features/ai_chat/widgets/chat_settings_bottom_sheet.dart';
import 'package:msbridge/features/ai_chat/widgets/empty_state.dart';
import 'package:msbridge/features/ai_chat/widgets/message_bubble.dart';
import 'package:msbridge/features/ai_chat/widgets/typing_indicator.dart';
import 'package:msbridge/features/ai_chat_history/chat_history.dart';
import 'package:msbridge/widgets/appbar.dart';
import 'package:msbridge/widgets/snakbar.dart';

// removed unused imports after refactor

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
  DateTime? _lastSendAt; // Rate limiting guard
  static const int _minSendIntervalMs = 1200; // Basic rate limit
  int _prevMessagesLength = 0;

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
      resizeToAvoidBottomInset: false,
      backgroundColor: colorScheme.surface,
      appBar: CustomAppBar(
        title: "AI Assistant",
        backbutton: false,
        actions: [
          IconButton(
            icon: Icon(
              LineIcons.plusCircle,
              color: colorScheme.primary,
              size: 24,
            ),
            onPressed: () => _confirmStartNewChat(context),
            tooltip: 'New Chat',
            style: IconButton.styleFrom(
              backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(
              LineIcons.cog,
              color: colorScheme.primary,
              size: 24,
            ),
            onPressed: () => _showChatSettingsBottomSheet(context),
            tooltip: 'AI Chat Settings',
            style: IconButton.styleFrom(
              backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
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
                  // Auto-scroll only when new messages are appended and user is near the bottom
                  final int currentLen = chat.messages.length;
                  if (currentLen > _prevMessagesLength &&
                      _scrollController.hasClients) {
                    // Guard against not attached / no positions
                    final position = _scrollController.position;
                    final double distanceFromBottom =
                        (position.maxScrollExtent - position.pixels).abs();
                    const double kAutoScrollThreshold = 200.0;
                    if (distanceFromBottom < kAutoScrollThreshold) {
                      _scrollToBottom();
                    }
                  }
                  _prevMessagesLength = currentLen;
                });
                if (chat.messages.isEmpty) {
                  return const ChatEmptyState();
                }
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  itemCount: chat.messages.length,
                  cacheExtent: 500, // Reduced for better performance
                  itemBuilder: (context, index) => MessageBubble(
                    key: ValueKey('${chat.messages[index].text}_$index'),
                    message: chat.messages[index],
                  ),
                );
              },
            ),
          ),
          if (_isTyping) TypingIndicator(colorScheme: colorScheme),
          ChatComposer(
            isSending: _isSending,
            controller: _controller,
            onSend: () => _sendMessage(context),
          ),
        ],
      ),
    );
  }

  void _confirmStartNewChat(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colorScheme.surface,
        title: Text(
          'Start New Chat?',
          style: theme.textTheme.titleMedium?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'This will clear the current conversation view. Your previous chats stay saved in history.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              final chat = Provider.of<ChatProvider>(context, listen: false);
              chat.startNewChat();
              if (mounted) {
                CustomSnackBar.show(context, 'Started a new chat',
                    isSuccess: true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
            ),
            child: const Text('New Chat'),
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

    // Simple rate-limit to prevent API spam and accidental double taps
    final now = DateTime.now();
    if (_lastSendAt != null &&
        now.difference(_lastSendAt!).inMilliseconds < _minSendIntervalMs) {
      CustomSnackBar.show(context, 'Please wait a moment before sending again');
      return;
    }
    _lastSendAt = now;

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

    // Clear the input immediately and disable composer until response
    _controller.clear();
    FocusScope.of(context).unfocus();
    setState(() {
      _isSending = true;
      _isTyping = true;
    });

    final Stopwatch sw = Stopwatch()..start();
    final int promptLength = question.length;
    int imageCount = 0;
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

      // Main request
      final response = await chat.ask(
        question,
        includePersonal: canIncludePersonal,
        includeMsNotes: shouldIncludeMsNotes,
      );
      sw.stop();
      FlutterBugfender.log(
          'AI chat success: latency=${sw.elapsedMilliseconds}ms, prompt_len=$promptLength, personal=$canIncludePersonal, msnotes=$shouldIncludeMsNotes, images=$imageCount');
      if (response == null && chat.hasError && context.mounted) {
        CustomSnackBar.show(context,
            'Failed to get AI response. You can retry using the retry button.');
      }
    } catch (e) {
      FlutterBugfender.error('Unexpected error: $e');
      try {
        sw.stop();
        FlutterBugfender.sendCrash(
          'AI chat request failed: $e | latency_ms=${sw.elapsedMilliseconds} | prompt_length=$promptLength | include_personal=$canIncludePersonal | include_msnotes=$shouldIncludeMsNotes',
          StackTrace.current.toString(),
        );
        FlutterBugfender.error('AI chat error: $e');
      } catch (e) {
        FlutterBugfender.sendCrash(
          'AI chat request failed: $e',
          StackTrace.current.toString(),
        );
      }
      if (context.mounted) {
        CustomSnackBar.show(context, 'Unexpected error, Please contact support',
            isSuccess: false);
      }
    } finally {
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
    showDialog(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final colorScheme = theme.colorScheme;
        return AlertDialog(
          backgroundColor: colorScheme.surface,
          title: Text(
            'Clear chat?',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            'This will remove all messages in the current conversation.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                chat.clearChat();
                if (context.mounted) {
                  CustomSnackBar.show(context, 'Chat cleared', isSuccess: true);
                }
              },
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );
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
