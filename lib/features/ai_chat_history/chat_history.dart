// Chat History Bottom Sheet

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_bugfender/flutter_bugfender.dart';
// removed: line_icons not used in this file after refactor
import 'package:provider/provider.dart';

// Project imports:
import 'package:msbridge/core/ai/chat_provider.dart';
import 'package:msbridge/core/database/chat_history/chat_history.dart';
import 'package:msbridge/core/provider/chat_history_provider.dart';
import 'package:msbridge/widgets/snakbar.dart';
import 'package:msbridge/features/ai_chat_history/widgets/history_item.dart';
import 'package:msbridge/features/ai_chat_history/widgets/history_header.dart';
import 'package:msbridge/features/ai_chat_history/widgets/empty_history.dart';

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
              color: colorScheme.outline.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          HistoryHeader(
            onClearAll: () => _clearAllHistory(
              context,
              Provider.of<ChatHistoryProvider>(context, listen: false),
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
                  return const EmptyHistory();
                }

                return NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (notification.metrics.pixels >=
                            notification.metrics.maxScrollExtent - 200 &&
                        historyProvider.hasMore &&
                        !historyProvider.isPaging) {
                      historyProvider.loadMore();
                    }
                    return false;
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: historyProvider.chatHistories.length +
                        (historyProvider.hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= historyProvider.chatHistories.length) {
                        return Padding(
                          padding: const EdgeInsets.all(16),
                          child: Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colorScheme.primary,
                              ),
                            ),
                          ),
                        );
                      }
                      final history = historyProvider.chatHistories[index];
                      return HistoryItem(
                        history: history,
                        onLoad: () async => await _loadChat(context, history),
                        onDelete: () => _deleteChat(context, history),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // history item moved to widgets/history_item.dart

  Future<void> _loadChat(BuildContext context, ChatHistory history) async {
    final chat = Provider.of<ChatProvider>(context, listen: false);

    try {
      await chat.loadChatFromHistory(history);

      if (context.mounted) {
        CustomSnackBar.show(context, 'Chat loaded from history',
            isSuccess: true);
        Navigator.pop(context);
      }
    } catch (e) {
      FlutterBugfender.error('Failed to load chat from history: $e');

      if (context.mounted) {
        CustomSnackBar.show(context, 'Failed to load chat: $e',
            isSuccess: false);
      }
    }
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
            onPressed: () async {
              Navigator.pop(context);
              final historyProvider = Provider.of<ChatHistoryProvider>(
                context,
                listen: false,
              );
              try {
                await historyProvider.deleteChatHistory(history.id);
                if (context.mounted) {
                  CustomSnackBar.show(context, 'Chat deleted', isSuccess: true);
                }
              } catch (e) {
                FlutterBugfender.error('Failed to delete chat: $e');
                if (context.mounted) {
                  CustomSnackBar.show(context, 'Failed to delete: $e',
                      isSuccess: false);
                }
              }
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
            onPressed: () async {
              Navigator.pop(context);
              try {
                await historyProvider.clearAllChatHistories();
                if (context.mounted) {
                  CustomSnackBar.show(context, 'All history cleared',
                      isSuccess: true);
                }
              } catch (e) {
                FlutterBugfender.error(
                    'Failed to clear all chat histories: $e');
                if (context.mounted) {
                  CustomSnackBar.show(
                      context, 'Failed to clear all history: $e',
                      isSuccess: false);
                }
              }
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

  // date formatting moved to history item or centralized utils if needed
}
