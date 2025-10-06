// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:line_icons/line_icons.dart';

// Project imports:
import 'package:msbridge/core/database/chat_history/chat_history.dart';

class HistoryItem extends StatelessWidget {
  const HistoryItem({
    super.key,
    required this.history,
    required this.onLoad,
    required this.onDelete,
  });

  final ChatHistory history;
  final VoidCallback onLoad;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: colorScheme.primary.withValues(alpha: 0.2),
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
                color: colorScheme.primary.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Model: ${history.modelName}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.primary.withValues(alpha: 0.5),
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
        trailing: IconButton(
          tooltip: 'Actions',
          icon: Icon(
            Icons.more_horiz,
            color: colorScheme.primary.withValues(alpha: 0.7),
          ),
          onPressed: () {
            _showActions(context, onLoad, onDelete);
          },
        ),
        onTap: onLoad,
      ),
    );
  }

  void _showActions(
      BuildContext context, VoidCallback onLoad, VoidCallback onDelete) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      isScrollControlled: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.outline.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child:
                      Icon(Icons.refresh, color: colorScheme.primary, size: 18),
                ),
                title: Text(
                  'Load Chat',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  onLoad();
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: colorScheme.error.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child:
                      Icon(LineIcons.trash, color: colorScheme.error, size: 18),
                ),
                title: Text(
                  'Delete',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  onDelete();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}
