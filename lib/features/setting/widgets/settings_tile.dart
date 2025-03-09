import 'package:flutter/material.dart';

class SettingsTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final String? versionNumber;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Widget? child;

  const SettingsTile({
    super.key,
    required this.title,
    required this.icon,
    this.versionNumber,
    this.onTap,
    this.trailing,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        splashColor: theme.colorScheme.secondary.withOpacity(0.2),
        highlightColor: theme.colorScheme.secondary.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                leading:
                    Icon(icon, color: theme.colorScheme.secondary, size: 24),
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title),
                    if (versionNumber != null && versionNumber!.isNotEmpty)
                      Text(
                        versionNumber!,
                        style: TextStyle(
                          color: theme.colorScheme.primary.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                  ],
                ),
                trailing: trailing ??
                    (onTap != null
                        ? Icon(Icons.chevron_right,
                            size: 16, color: theme.colorScheme.primary)
                        : null),
              ),
              if (child != null) child!,
            ],
          ),
        ),
      ),
    );
  }
}
