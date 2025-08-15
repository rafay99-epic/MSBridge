import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:msbridge/core/ai/chat_provider.dart';
import 'package:msbridge/core/provider/ai_consent_provider.dart';
import 'package:msbridge/core/provider/chat_history_provider.dart';
import 'package:provider/provider.dart';
import 'package:msbridge/widgets/appbar.dart';
import 'package:msbridge/widgets/snakbar.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:msbridge/core/database/chat_history/chat_history.dart';

class ChatAssistantPage extends StatefulWidget {
  const ChatAssistantPage({super.key});

  @override
  State<ChatAssistantPage> createState() => _ChatAssistantPageState();
}

class _ChatAssistantPageState extends State<ChatAssistantPage>
    with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _includePersonal = true;
  bool _includeMsNotes = true;
  bool _isTyping = false;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animations with optimized durations for better performance
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400), // Reduced from 800ms
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300), // Reduced from 600ms
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut, // Changed from easeOutCubic for better performance
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2), // Reduced from 0.3 for better performance
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut, // Changed from easeOutCubic for better performance
    ));

    // Start animations
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => ChatHistoryProvider()),
      ],
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: const CustomAppBar(
          title: "Ask AI",
          backbutton: false,
        ),
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Column(
              children: [
                // Header Section with Consent and Filters
                _buildHeaderSection(context, colorScheme, theme),

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
                          : _buildChatMessages(
                              context, chat, colorScheme, theme);
                    },
                  ),
                ),

                // Typing Indicator
                if (_isTyping) _buildTypingIndicator(context, colorScheme),

                // Message Composer
                _buildComposer(context, colorScheme, theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection(
      BuildContext context, ColorScheme colorScheme, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary.withOpacity(0.05),
            colorScheme.secondary.withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.primary.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Consent Card
          Consumer<AiConsentProvider>(
            builder: (context, consent, _) {
              return Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.1),
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
                    onChanged: (v) async {
                      await consent.setEnabled(v);
                      if (!v) {
                        CustomSnackBar.show(
                            context, 'AI access to notes disabled');
                      }
                    },
                    activeColor: colorScheme.primary,
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 16),

          // Filter Chips
          Text(
            'Include in AI responses:',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.primary.withOpacity(0.7),
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
                selected: _includePersonal,
                onSelected: (v) => setState(() => _includePersonal = v),
                selectedColor: colorScheme.primary.withOpacity(0.1),
                checkmarkColor: colorScheme.primary,
                labelStyle: TextStyle(
                  color: _includePersonal
                      ? colorScheme.primary
                      : colorScheme.primary.withOpacity(0.7),
                  fontWeight:
                      _includePersonal ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
              FilterChip(
                label: const Text('MS Notes'),
                selected: _includeMsNotes,
                onSelected: (v) => setState(() => _includeMsNotes = v),
                selectedColor: colorScheme.primary.withOpacity(0.1),
                checkmarkColor: colorScheme.primary,
                labelStyle: TextStyle(
                  color: _includeMsNotes
                      ? colorScheme.primary
                      : colorScheme.primary.withOpacity(0.7),
                  fontWeight:
                      _includeMsNotes ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Status and Actions Section
          Consumer<ChatProvider>(
            builder: (context, chat, _) {
              return Row(
                children: [
                  // Status indicator with flexible width
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: chat.hasError
                            ? colorScheme.error.withOpacity(0.1)
                            : chat.isLoading
                                ? colorScheme.primary.withOpacity(0.1)
                                : colorScheme.secondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: chat.hasError
                              ? colorScheme.error
                              : chat.isLoading
                                  ? colorScheme.primary
                                  : colorScheme.secondary,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            chat.hasError
                                ? LineIcons.exclamationTriangle
                                : chat.isLoading
                                    ? LineIcons.clock
                                    : LineIcons.checkCircle,
                            size: 14,
                            color: chat.hasError
                                ? colorScheme.error
                                : chat.isLoading
                                    ? colorScheme.primary
                                    : colorScheme.secondary,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              chat.sessionStatus,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: chat.hasError
                                    ? colorScheme.error
                                    : chat.isLoading
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
                  ),

                  const SizedBox(width: 8),

                  // History button
                  OutlinedButton.icon(
                    onPressed: () => _showChatHistory(context),
                    icon: Icon(
                      LineIcons.history,
                      size: 16,
                      color: colorScheme.primary,
                    ),
                    label: Text(
                      'History',
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: colorScheme.primary),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Clear chat button
                  if (chat.messages.isNotEmpty)
                    OutlinedButton.icon(
                      onPressed: () => _clearChat(context),
                      icon: Icon(
                        LineIcons.trash,
                        size: 16,
                        color: colorScheme.error,
                      ),
                      label: Text(
                        'Clear Chat',
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
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
      BuildContext context, ColorScheme colorScheme, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
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
              color: colorScheme.primary.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: colorScheme.primary.withOpacity(0.2),
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
      itemBuilder: (context, index) {
        final message = chat.messages[index];
        final isUser = message.fromUser;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
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
                        ? colorScheme.error.withOpacity(0.15)
                        : colorScheme.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: message.isError
                          ? colorScheme.error.withOpacity(0.3)
                          : colorScheme.primary.withOpacity(0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (message.isError
                                ? colorScheme.error
                                : colorScheme.primary)
                            .withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
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
                              : colorScheme.primary.withOpacity(0.4),
                      width: message.isError ? 2 : 2.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isUser
                            ? colorScheme.primary.withOpacity(0.3)
                            : colorScheme.primary.withOpacity(0.15),
                        blurRadius: isUser ? 8 : 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isUser)
                        SelectableText(
                          message.text,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        )
                      else if (message.isError)
                        Column(
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
                                          content: SelectableText(
                                              message.errorDetails!),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context),
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
                        )
                      else
                        MarkdownBody(
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
                              backgroundColor:
                                  colorScheme.primary.withOpacity(0.15),
                              color: colorScheme.onSurface,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w600,
                            ),
                            codeblockDecoration: BoxDecoration(
                              color: colorScheme.primary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: colorScheme.primary.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                          ),
                          selectable: true,
                        ),
                    ],
                  ),
                ),
              ),
              if (isUser) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: colorScheme.primary.withOpacity(0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
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
        );
      },
    );
  }

  Widget _buildTypingIndicator(BuildContext context, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
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
                color: colorScheme.outline.withOpacity(0.2),
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
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.6),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  Widget _buildComposer(
      BuildContext context, ColorScheme colorScheme, ThemeData theme) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: colorScheme.outline.withOpacity(0.1),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: colorScheme.primary.withOpacity(0.4),
                    width: 2.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withOpacity(0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _controller,
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  decoration: InputDecoration(
                    hintText: 'Ask AI anything...',
                    hintStyle: TextStyle(
                      color: colorScheme.primary.withOpacity(0.7),
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
                  onSubmitted: (_) => _sendMessage(context),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Consumer2<ChatProvider, AiConsentProvider>(
              builder: (context, chat, consent, _) {
                return Container(
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: Icon(
                      LineIcons.paperPlane,
                      color: colorScheme.onPrimary,
                      size: 20,
                    ),
                    onPressed: () => _sendMessage(context),
                    style: IconButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _sendMessage(BuildContext context) async {
    final question = _controller.text.trim();
    if (question.isEmpty) return;

    final consent = Provider.of<AiConsentProvider>(context, listen: false);

    // Handle consent logic: Personal notes require consent, MS Notes don't
    if (!consent.enabled && _includePersonal) {
      CustomSnackBar.show(
          context, 'Personal notes disabled. AI will only access MS Notes.');
      // Continue with MS Notes only
    }

    setState(() {
      _isTyping = true;
    });

    try {
      final chat = Provider.of<ChatProvider>(context, listen: false);

      // Define note inclusion flags
      final canIncludePersonal = consent.enabled && _includePersonal;
      final shouldIncludeMsNotes = _includeMsNotes;

      // Start session if needed
      if (!chat.isReady) {
        // If personal notes are blocked but user wants them, show info message
        if (_includePersonal && !consent.enabled) {
          CustomSnackBar.show(context,
              'Personal notes disabled. AI will only access MS Notes.');
        }

        await chat.startSession(
          includePersonal: canIncludePersonal,
          includeMsNotes: shouldIncludeMsNotes,
        );

        // Check if session failed
        if (chat.hasError) {
          CustomSnackBar.show(
              context, chat.lastErrorMessage ?? 'Failed to start chat session');
          return;
        }
      }

      // Send the question
      final response = await chat.ask(
        question,
        includePersonal: canIncludePersonal,
        includeMsNotes: shouldIncludeMsNotes,
      );

      if (response != null) {
        _controller.clear();
      } else if (chat.hasError) {
        // Error is already handled by the provider and shown in chat
        CustomSnackBar.show(context,
            'Failed to get AI response. You can retry using the retry button.');
      }
    } catch (e) {
      CustomSnackBar.show(context, 'Unexpected error: $e');
    } finally {
      setState(() {
        _isTyping = false;
      });
    }
  }

  // Add retry functionality
  void _retryLastQuestion(BuildContext context) async {
    final chat = Provider.of<ChatProvider>(context, listen: false);
    final response = await chat.retryLastQuestion();

    if (response != null) {
      CustomSnackBar.show(context, 'Retry successful!', isSuccess: true);
    } else if (chat.hasError) {
      CustomSnackBar.show(context, 'Retry failed: ${chat.lastErrorMessage}');
    }
  }

  // Add clear chat functionality
  void _clearChat(BuildContext context) {
    final chat = Provider.of<ChatProvider>(context, listen: false);
    chat.clearChat();
    CustomSnackBar.show(context, 'Chat cleared', isSuccess: true);
  }

  // Show chat history
  void _showChatHistory(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ChatHistoryBottomSheet(),
    );
  }
}

// Chat History Bottom Sheet
class ChatHistoryBottomSheet extends StatelessWidget {
  const ChatHistoryBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.outline.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(
                  LineIcons.history,
                  color: colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Chat History',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Consumer<ChatHistoryProvider>(
                  builder: (context, historyProvider, _) {
                    return TextButton.icon(
                      onPressed: historyProvider.chatHistories.isNotEmpty
                          ? () => _clearAllHistory(context, historyProvider)
                          : null,
                      icon: Icon(
                        LineIcons.trash,
                        size: 16,
                        color: colorScheme.error,
                      ),
                      label: Text(
                        'Clear All',
                        style: TextStyle(
                          color: colorScheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // History List
          Expanded(
            child: Consumer<ChatHistoryProvider>(
              builder: (context, historyProvider, _) {
                if (historyProvider.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (historyProvider.chatHistories.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LineIcons.history,
                          size: 64,
                          color: colorScheme.primary.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No chat history yet',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: colorScheme.primary.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your conversations will appear here',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.primary.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: historyProvider.chatHistories.length,
                  itemBuilder: (context, index) {
                    final history = historyProvider.chatHistories[index];
                    return _buildHistoryItem(
                        context, history, colorScheme, theme);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(
    BuildContext context,
    ChatHistory history,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.primary.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: colorScheme.primary.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Icon(
            LineIcons.robot,
            color: colorScheme.primary,
            size: 20,
          ),
        ),
        title: Text(
          history.title,
          style: theme.textTheme.titleMedium?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${history.messages.length} messages',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.primary.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Model: ${history.modelName.split('-').first}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.primary.withOpacity(0.5),
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatDate(history.lastUpdated),
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.primary.withOpacity(0.4),
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: Icon(
            Icons.more_vert,
            color: colorScheme.primary.withOpacity(0.6),
          ),
          onSelected: (value) {
            switch (value) {
              case 'load':
                _loadChat(context, history);
                break;
              case 'delete':
                _deleteChat(context, history);
                break;
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'load',
              child: Row(
                children: [
                  Icon(
                    Icons.refresh,
                    size: 16,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text('Load Chat'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(
                    LineIcons.trash,
                    size: 16,
                    color: colorScheme.error,
                  ),
                  const SizedBox(width: 8),
                  Text('Delete'),
                ],
              ),
            ),
          ],
        ),
        onTap: () => _loadChat(context, history),
      ),
    );
  }

  void _loadChat(BuildContext context, ChatHistory history) {
    final chat = Provider.of<ChatProvider>(context, listen: false);
    chat.loadChatFromHistory(history);
    Navigator.pop(context);
    CustomSnackBar.show(context, 'Chat loaded from history', isSuccess: true);
    Navigator.pop(context);
  }

  void _deleteChat(BuildContext context, ChatHistory history) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Chat'),
        content: Text('Are you sure you want to delete "${history.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              final historyProvider = Provider.of<ChatHistoryProvider>(
                context,
                listen: false,
              );
              historyProvider.deleteChatHistory(history.id);
              CustomSnackBar.show(context, 'Chat deleted', isSuccess: true);
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _clearAllHistory(
      BuildContext context, ChatHistoryProvider historyProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All History'),
        content: const Text(
          'Are you sure you want to delete all chat history? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              historyProvider.clearAllChatHistories();
              CustomSnackBar.show(context, 'All history cleared',
                  isSuccess: true);
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }
}
