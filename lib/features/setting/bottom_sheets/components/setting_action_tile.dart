// setting_action_tile.dart
import 'package:flutter/material.dart';

class SettingActionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final bool isLoading;
  final bool isDisabled;

  const SettingActionTile({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.isLoading = false,
    this.isDisabled = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: (isLoading || isDisabled) ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDisabled
                ? colorScheme.surface.withOpacity(0.5)
                : colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.outline.withOpacity(isDisabled ? 0.05 : 0.1),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color:
                      colorScheme.primary.withOpacity(isDisabled ? 0.05 : 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: isDisabled
                      ? colorScheme.primary.withOpacity(0.3)
                      : colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDisabled
                            ? colorScheme.primary.withOpacity(0.3)
                            : colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDisabled
                            ? colorScheme.primary.withOpacity(0.3)
                            : colorScheme.primary.withOpacity(0.6),
                      ),
                    ),
                    if (isDisabled) ...[
                      const SizedBox(height: 4),
                      Text(
                        "This feature is currently disabled",
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.error.withOpacity(0.7),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (isLoading)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(colorScheme.primary),
                  ),
                )
              else if (isDisabled)
                Icon(
                  Icons.block,
                  size: 20,
                  color: colorScheme.error.withOpacity(0.5),
                )
              else
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: colorScheme.primary.withOpacity(0.5),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
