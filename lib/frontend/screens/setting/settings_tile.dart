import 'package:flutter/material.dart';

class SettingsTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final String? versionNumber; // Make versionNumber nullable
  final VoidCallback? onTap;

  const SettingsTile({
    Key? key,
    required this.title,
    required this.icon,
    this.versionNumber, // No longer required
    this.onTap,
  }) : super(key: key);

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
          child: ListTile(
            leading: Icon(icon, color: theme.colorScheme.secondary, size: 24),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(color: theme.colorScheme.primary),
                ),
                if (versionNumber != null &&
                    versionNumber!
                        .isNotEmpty) // Check if versionNumber is not null and not empty
                  Text(
                    versionNumber!,
                    style: TextStyle(
                        color: theme.colorScheme.primary.withOpacity(0.7),
                        fontSize: 14),
                  ),
              ],
            ),
            trailing: onTap != null
                ? Icon(Icons.chevron_right,
                    size: 16, color: theme.colorScheme.primary)
                : null,
          ),
        ),
      ),
    );
  }
}
