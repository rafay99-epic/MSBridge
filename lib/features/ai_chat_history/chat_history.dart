// Chat History Bottom Sheet
import 'package:flutter/material.dart';
import 'package:flutter_bugfender/flutter_bugfender.dart';
import 'package:line_icons/line_icons.dart';
import 'package:msbridge/core/ai/chat_provider.dart';
import 'package:msbridge/core/database/chat_history/chat_history.dart';
import 'package:msbridge/core/provider/chat_history_provider.dart';
import 'package:msbridge/widgets/snakbar.dart';
import 'package:provider/provider.dart';

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
              'Model: ${history.modelName}',
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
          onSelected: (value) async {
            switch (value) {
              case 'load':
                await _loadChat(context, history);
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
        onTap: () async => await _loadChat(context, history),
      ),
    );
  }

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
