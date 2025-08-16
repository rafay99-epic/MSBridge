import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';

class QuickActionsWidget extends StatelessWidget {
  final ThemeData theme;
  final ColorScheme colorScheme;
  final VoidCallback onLogout;
  final VoidCallback onSyncNow;
  final VoidCallback onBackup;

  const QuickActionsWidget({
    super.key,
    required this.theme,
    required this.colorScheme,
    required this.onLogout,
    required this.onSyncNow,
    required this.onBackup,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: QuickActionTile(
              title: "Logout",
              icon: LineIcons.alternateSignOut,
              color: Colors.red,
              onTap: onLogout,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: QuickActionTile(
              title: "Sync Now",
              icon: LineIcons.syncIcon,
              color: colorScheme.secondary,
              onTap: onSyncNow,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: QuickActionTile(
              title: "Backup",
              icon: LineIcons.download,
              color: colorScheme.primary,
              onTap: onBackup,
            ),
          ),
        ],
      ),
    );
  }
}

class QuickActionTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const QuickActionTile({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 24,
                color: color,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
